#!/usr/bin/env python3
"""
Enables access to services deployed on the Stackable platform
"""

import argparse
import os
import re
import socket
import subprocess
import sys

from argparse import Namespace
from contextlib import closing
from kubernetes import client, config
from tabulate import tabulate

# An empty list of port names to expose means expose all ports of that service
SERVICES_TO_EXPOSE = {
    r".*minio.*-console$": ["http-console"],
    r".*opa": ["http", "https"],
    r".*druid-(broker|coordinator|historical|middlemanager|router)": ["http", "https"],
    r".*hbase-(master|regionserver|restserver)": ["ui"],
    r".*spark-master": ["http", "https"],
    r".*spark-slave": ["http", "https"],
    r".*spark-history-server": ["http", "https"],
    r".*trino-(coordinator|worker)": ["http", "https"],
    r".*nifi": ["http", "https"],
    r".*airflow-webserver": ["airflow"],
    r".*superset": ["superset"],
    r".*simple-hdfs-namenode-.*$(?<!-[0-9])(?<!-[0-9][0-9])(?<!-[0-9][0-9][0-9])": ["http", "https"],
    r".*simple-hdfs-datanode-.*$(?<!-[0-9])(?<!-[0-9][0-9])(?<!-[0-9][0-9][0-9])": ["http", "https"],
    r".*simple-hdfs-journalnode-.*$(?<!-[0-9])(?<!-[0-9][0-9])(?<!-[0-9][0-9][0-9])": ["http", "https"],
    r"alertmanager-operated": ["http-web"],
    r"prometheus-operated": ["http-web"],
    r"prometheus-operator-grafana": ["http-web"],
}

# Shell command to print additional infos like credentials
# The env variable SERVICE_NAME will be set to the service name
# The env variable NAMESPACE will be set to the namespace of the service
EXTRA_INFO = {
    r"prometheus-operator-grafana$": 'kubectl -n $NAMESPACE get secret prometheus-operator-grafana --template=\'user: {{index .data "admin-user" | base64decode}}, password: {{index .data "admin-password" | base64decode}}\'',
    r"minio.*-console$": 'kubectl -n $NAMESPACE get secret $(echo "$SERVICE_NAME" | sed "s/-console$/-secret/") --template=\'accesskey: {{index .data "accesskey" | base64decode}}, secretkey: {{index .data "secretkey" | base64decode}}\'',
    r".*superset.*-external$": 'kubectl -n $NAMESPACE get secret $(kubectl -n $NAMESPACE get supersetclusters.superset.stackable.tech $(echo "$SERVICE_NAME" | sed "s/-external$//") --template=\'{{.spec.credentialsSecret}}\') --template=\'user: {{index .data "adminUser.username" | base64decode}}, password: {{index .data "adminUser.password" | base64decode}}\'',
}

K8S = None
K8S_NODE_IPS = {}

PROCESSES = []
SERVICES = []


def check_args() -> Namespace:
    """Parse the given CLI arguments"""
    parser = argparse.ArgumentParser(
        description="This tool can be used to forward services of Stackable products to the local machine."
    )
    parser.add_argument('--namespace', '-n', required=False,
                        help='The namespace of the services to forward. As a default the current kubectl context will be used')
    parser.add_argument('--all-namespaces', '-a', action='store_true',
                        help='Forward services from all namespaces')
    parser.add_argument('--all-services', action='store_true',
                        help='Forward all services regardles of the name or the exposed ports')
    parser.add_argument('--dont-use-port-forward', '-d', action='store_true',
                        help='Dont use "kubectl port-forward", instead return the NodeIP and NodePort. This may cause problems as many services dont have the nodePorts attribute, services having multiple endpoints or kubernetes nodes having multiple InternalIPs or ExternalIPs (in this case we pick a random IP of that list)')
    parser.add_argument('--use-internal-node-ip', action='store_true',
                        help='Used in combination with --dont-use-port-forward. When set it prefers a nodes InternalIP over the ExternalIP')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='In case of using port-forward show stdout output of "kubectl port-forward" command')
    return parser.parse_args()


def main():
    """Main function executed. Blocking (waits for all processes to finish)."""
    global K8S

    args = check_args()

    config.load_kube_config()
    namespace = args.namespace or config.list_kube_config_contexts()[1]['context'].get("namespace", "default")
    K8S = client.CoreV1Api()
    calculate_k8s_node_ips(args)

    if args.all_namespaces:
        services = K8S.list_service_for_all_namespaces()
    else:
        services = K8S.list_namespaced_service(namespace=namespace)

    for service_spec in services.items:
        service_namespace = service_spec.metadata.namespace
        service_name = service_spec.metadata.name

        for port_spec in service_spec.spec.ports:
            service_port = port_spec.port
            service_port_name = port_spec.name
            service_node_port = port_spec.node_port or '<no nodePort attribute on service>'
            if shall_expose_service(service_name, service_port_name) or args.all_services:
                if args.dont_use_port_forward:
                    calculate_node_address(service_namespace, service_name, service_port, service_port_name,
                                           service_node_port)
                else:
                    forward_port(service_namespace, service_name, service_port, service_port_name, args.verbose)

    print(tabulate(SERVICES, headers=['Namespace', 'Service', 'Port', 'Name', 'URL', 'Extra info'],
                   tablefmt='psql'))
    print()

    for process in PROCESSES:
        process.wait()


def calculate_k8s_node_ips(args):
    """Loops over the available k8s nodes and extracts the NodeIP information"""
    for node in K8S.list_node().items:
        node_name = node.metadata.name
        internal_node_ip = None
        external_node_ip = None

        for address in node.status.addresses:
            if address.type == 'InternalIP':
                internal_node_ip = address.address
            elif address.type == 'ExternalIP':
                external_node_ip = address.address

        if args.use_internal_node_ip:
            node_ip = internal_node_ip or external_node_ip
        else:
            node_ip = external_node_ip or internal_node_ip

        if node_ip is None:
            raise Exception(f"Could not find a valid InternalIP or ExternalIP for node {node_name}")

        K8S_NODE_IPS[node_name] = node_ip

def shall_expose_service(service_name, service_port_name) -> bool:
    """Should the particular port of the services be exposed?"""
    for regex, port_names_to_expose in SERVICES_TO_EXPOSE.items():
        if re.match(regex, service_name) \
                and (service_port_name in port_names_to_expose or len(port_names_to_expose) == 0):
            return True
    return False


def find_free_port() -> int:
    """Find an unused ports that can use to bind port-forwarding to"""
    with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as sock:
        sock.bind(('localhost', 0))
        return sock.getsockname()[1]


def forward_port(service_namespace, service_name, service_port, service_port_name, verbose):
    """Execute a "kubectl port-forward" command to forward to specified service. Non-clocking (spawns process in background). """
    local_port = find_free_port()
    command = ["kubectl", "-n", service_namespace, "port-forward", f"service/{service_name}",
               f"{local_port}:{service_port}"]
    if verbose:
        process = subprocess.Popen(command)
    else:
        with open(os.devnull, 'wb') as stdout:
            process = subprocess.Popen(command, stdout=stdout)
    PROCESSES.append(process)
    SERVICES.append([
        service_namespace,
        service_name,
        service_port,
        service_port_name,
        f"http://localhost:{local_port}",
        get_extra_info(service_namespace, service_name),
    ])


def calculate_node_address(service_namespace, service_name, service_port, service_port_name, service_node_port):
    """Calculate the NodeIP and NodePort combination so that the service can be accessed directly without a port-forward"""
    endpoint = K8S.read_namespaced_endpoints(namespace=service_namespace, name=service_name)
    if endpoint.subsets is not None and len(endpoint.subsets) > 0:
        node_name = endpoint.subsets[0].addresses[0].node_name
        node_ip = K8S_NODE_IPS[node_name]

        SERVICES.append([
            service_namespace,
            service_name,
            service_port,
            service_port_name,
            f"http://{node_ip}:{service_node_port}",
            get_extra_info(service_namespace, service_name),
        ])


def get_extra_info(service_namespace, service_name) -> str:
    """Run the configured shell command to get some addition infos (like credentials) that we can show the user"""
    command = None
    for regex, command_from_loop in EXTRA_INFO.items():
        if re.match(regex, service_name):
            command = command_from_loop
    if command is None:
        return ""
    env = os.environ.copy()
    env["SERVICE_NAME"] = service_name
    env["NAMESPACE"] = service_namespace
    return subprocess.run(command, shell=True, capture_output=True, check=False, env=env).stdout.decode('utf-8')


def cleanup():
    """Stops the running background processes"""
    if len(PROCESSES) > 0:
        print(f"Stopping {len(PROCESSES)} port-forwards")
        for process in PROCESSES:
            process.kill()
        PROCESSES.clear()


if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        cleanup()
    finally:
        cleanup()
