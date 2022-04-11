#!/usr/bin/env python3

import argparse
import json
import logging
import re
import requests
import shutil
import subprocess
import sys
import time
from argparse import Namespace

VALID_OPERATORS = ["airflow", "druid", "hbase", "hdfs", "hive", "kafka", "nifi", "opa", "secret", "spark", "spark-k8s", "superset", "trino", "zookeeper"]

DEFAULT_KIND_CLUSTER_NAME = "integration-tests"

HELM_DEV_REPO_NAME = "stackable-dev"
HELM_DEV_REPO_URL = "https://repo.stackable.tech/repository/helm-dev"
HELM_TEST_REPO_NAME = "stackable-test"
HELM_TEST_REPO_URL = "https://repo.stackable.tech/repository/helm-test"
HELM_STABLE_REPO_NAME = "stackable"
HELM_STABLE_REPO_URL = "https://repo.stackable.tech/repository/helm-stable"
HELM_PROMETHEUS_REPO_NAME = "prometheus-community"
HELM_PROMETHEUS_REPO_URL = "https://prometheus-community.github.io/helm-charts"
HELM_PROMETHEUS_CHART_NAME = "kube-prometheus-stack"

# replacement for switch/match case
OPERATOR_TO_EXAMPLE_REPO = {
  "airflow": "https://raw.githubusercontent.com/stackabletech/airflow-operator/main/examples/simple-airflow-cluster.yaml",
  "druid": "https://raw.githubusercontent.com/stackabletech/druid-operator/main/examples/simple-druid-cluster.yaml",
  "hbase": "https://raw.githubusercontent.com/stackabletech/hbase-operator/main/examples/simple-hbase-cluster.yaml",
  "hdfs": "https://raw.githubusercontent.com/stackabletech/hdfs-operator/main/examples/simple-hdfs-cluster.yaml",
  "hive": "https://raw.githubusercontent.com/stackabletech/hive-operator/main/examples/simple-hive-cluster.yaml",
  "kafka": "https://raw.githubusercontent.com/stackabletech/kafka-operator/main/examples/simple-kafka-cluster.yaml",
  "nifi": "https://raw.githubusercontent.com/stackabletech/nifi-operator/main/examples/simple-nifi-cluster.yaml",
  "opa": "https://raw.githubusercontent.com/stackabletech/opa-operator/main/examples/simple-opa-cluster.yaml",
  # we do not need to provide the secret examples
  "secret": None,
  "spark": "https://raw.githubusercontent.com/stackabletech/spark-operator/main/examples/simple-spark-cluster.yaml",
  "spark-k8s": None,   # TODO
  "superset": "https://raw.githubusercontent.com/stackabletech/superset-operator/main/examples/simple-superset-cluster.yaml",
  "trino": "https://raw.githubusercontent.com/stackabletech/trino-operator/main/examples/simple-trino-cluster.yaml",
  "zookeeper": "https://raw.githubusercontent.com/stackabletech/zookeeper-operator/main/examples/simple-zookeeper-cluster.yaml",
}

KIND_CLUSTER_DEFINITION = """
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
  kubeadmConfigPatches:
    - |
      kind: JoinConfiguration
      nodeRegistration:
        kubeletExtraArgs:
          node-labels: node=1,
- role: worker
  kubeadmConfigPatches:
    - |
      kind: JoinConfiguration
      nodeRegistration:
        kubeletExtraArgs:
          node-labels: node=2
- role: worker
  kubeadmConfigPatches:
    - |
      kind: JoinConfiguration
      nodeRegistration:
        kubeletExtraArgs:
          node-labels: node=3
"""

MINIO_SERVICE = """
apiVersion: v1
kind: Service
metadata:
  name: minio-external
spec:
  type: NodePort
  selector:
    v1.min.io/tenant: minio1
  ports:
    - port: 80
      targetPort: 9000
"""

PROMETHEUS_SCRAPE_SERVICE = """
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: scrape-label
  labels:
    release: prometheus-operator
spec:
  endpoints:
  - port: metrics
  jobLabel: app.kubernetes.io/instance
  selector:
    matchLabels:
      prometheus.io/scrape: "true"
  namespaceSelector:
    any: true      
"""


def check_args() -> Namespace:
  parser = argparse.ArgumentParser(
    description="This tool can be used to install the Stackable Kubernetes Operators into a Kubernetes cluster using Helm. "
                "It can optionally also create a kind cluster."
  )
  parser.add_argument('--operator', '-o', required=True, nargs='+', type=operator_from_input,
                      help='A list of Stackable operators to install. Operators can be specified in the form \"name[=version]\"', )
  parser.add_argument('--provision', '-p', required=False, help='A folder with resources or a single file to be deployed after the cluster has been created.')
  parser.add_argument('--kind', '-k', required=False, nargs='?', default=False, const=DEFAULT_KIND_CLUSTER_NAME, metavar="CLUSTER NAME",
                      help="When provided we'll automatically create a 4 node kind cluster. "
                           f"If this was provided with no argument the kind cluster will have the name '{DEFAULT_KIND_CLUSTER_NAME}' "
                           "Otherwise the provided name will be used",
                      )
  parser.add_argument('--debug', '-d', action='store_true', required=False, help="Will print additional debug statements (e.g. output from all run commands)")
  parser.add_argument('--prometheus', '-m', action='store_true', required=False, help="Will install the Prometheus operator for scraping metrics.")
  parser.add_argument('--example', '-e', action='store_true', required=False, help="Will install the 'simple' examples for the operators specified via '--operator' or '-o'")
  args = parser.parse_args()

  log_level = 'DEBUG' if args.debug else 'INFO'
  logging.basicConfig(
    level=log_level,
    format='%(asctime)s %(levelname)s: %(message)s',
    stream=sys.stdout
  )

  return args


def check_prerequisites():
  """ Checks whether Helm is installed"""
  helper_command_exists('helm')


def create_kind_cluster(name: str):
  """ Creates a kind cluster with four nodes and the given name if it doesn't exist already"""
  helper_command_exists('kind')
  helper_check_docker_running()

  logging.debug(f"Checking whether kind cluster [{name}] already exists")
  output = helper_execute(['kind', 'get', 'clusters']).splitlines()
  if name in output:
    logging.info(f"Kind cluster [{name}] already running - continuing")
    return

  logging.info(f"Kind cluster [{name}] missing - creating now")
  helper_execute(['kind', 'create', 'cluster', '--name', name, '--config', '-'], KIND_CLUSTER_DEFINITION)
  logging.info(f'Successfully created kind cluster [{name}]')


def check_kubernetes_available():
  """ Checks if Kubernetes is available, this is a naive approach but better than nothing """
  logging.info("Checking if Kubernetes is available")
  helper_execute(['kubectl', 'cluster-info'])
  logging.debug("Successfully tested for Kubernetes, seems to be available")


def install_stackable_operator(name: str, version: str = None):
  """ This installs a Stackable Operator release in Helm.

  It makes sure that the proper repository is installed and install either a specific version or the latest development version
  """
  install_dependencies(name)

  logging.info(f"Installing [{name}] in version [{version}]")
  operator_name = f"{name}-operator"

  if version:
    if "-nightly" in version:
      args = [f"--version={version}", "--devel"]
      helper_install_helm_release(operator_name, operator_name, HELM_DEV_REPO_NAME, HELM_DEV_REPO_URL, args)
    elif "-pr" in version:
      args = [f"--version={version}", "--devel"]
      helper_install_helm_release(operator_name, operator_name, HELM_TEST_REPO_NAME, HELM_TEST_REPO_URL, args)
    else:
      helper_install_helm_release(operator_name, operator_name, HELM_STABLE_REPO_NAME, HELM_STABLE_REPO_URL, [])
  else:
    args = ["--devel"]
    helper_install_helm_release(operator_name, operator_name, HELM_DEV_REPO_NAME, HELM_DEV_REPO_URL, args)


def install_prometheus():
  """This installs the Prometheus Operator in Helm

  It makes sure that the proper repository is installed and deploys a generic ServiceMonitor service
  """
  helper_add_helm_repo(HELM_PROMETHEUS_REPO_NAME, HELM_PROMETHEUS_REPO_URL)
  release = helper_find_helm_release(HELM_PROMETHEUS_REPO_NAME, HELM_PROMETHEUS_CHART_NAME)

  if release:
    logging.info(f"Prometheus Operator already running release with name [{release['name']}] and chart [{release['chart']}] - skipping installation")
    return

  helper_install_helm_release("prometheus-operator", HELM_PROMETHEUS_CHART_NAME, HELM_PROMETHEUS_REPO_NAME, HELM_PROMETHEUS_REPO_URL)
  helper_execute(['kubectl', 'apply', '-f', '-'], PROMETHEUS_SCRAPE_SERVICE)


def install_examples(operator: str):
  example_url = OPERATOR_TO_EXAMPLE_REPO[operator]
  if example_url:
    example_file_name = "/tmp/simple-" + operator + "-cluster.yaml"
    r = requests.get(example_url, allow_redirects=True)
    if r.status_code == 200:
      open(example_file_name, "wb").write(r.content)
      helper_execute(['kubectl', 'apply', '-f', example_file_name])
      helper_execute(['rm', example_file_name])
      logging.info(f"Successfully applied example from [{example_url}]")
    else:
      logging.info(f"Error {r.status_code}: {r.reason}")
  else:
    logging.info(f"No examples found for [{operator}] - skipping.")


def helper_check_docker_running():
  """Check if Docker is running, exit the program if not"""

  # Pylint suggests using check=True here, I didn't know about it at the time and don't think it's worth changing now
  output = subprocess.run(['docker', 'info'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
  if output.returncode != 0:
    logging.error("This script uses docker, and it isn't running - please start docker and try again")
    logging.debug(output.stdout)
    sys.exit(1)
  logging.debug("Docker seems to be running - continuing")


def helper_add_helm_repo(name: str, url: str) -> str:
  """Adds Helm repository if it does not exist yet (it looks for a repository with the same URL, not name).

  An `update` command will also be run in either case.

  :return: The name of the repository, might differ from the passed name if it did already exist
  """
  logging.debug(f"Checking whether Helm repository [{name}] already exists")

  # WARNING: This can fail due to https://github.com/helm/helm/pull/10519
  output = json.loads(helper_execute(['helm', 'repo', 'list', '-o', 'json']))
  repo = next((item for item in output if item['url'] == url), None)

  if repo:
    logging.debug(f"Found existing repository [{repo['name']}] with URL [{repo['url']}]")
    helper_execute(['helm', 'repo', 'update', name])
    return repo['name']

  logging.info(f"Helm repository [{name}] (URL {url}) missing - adding now")
  helper_execute(['helm', 'repo', 'add', name, url])
  helper_execute(['helm', 'repo', 'update', name])
  logging.debug(f"Successfully added repository [{name}] with URL [{url}]")
  return name


def install_dependencies(name: str):
  # In Python 3.10 this could have been a match-case statement
  options = {
    "airflow": install_dependencies_airflow,
    "druid": install_dependencies_druid,
    "hbase": install_dependencies_hbase,
    "kafka": install_dependencies_kafka,
    "nifi": install_dependencies_nifi,
    "opa": install_dependencies_opa,
    "superset": install_dependencies_superset,
    "spark-k8s": install_dependencies_spark_k8s,
    "trino": install_dependencies_trino,
    "hdfs": install_dependencies_hdfs,
  }
  if name in options:
    options[name]()


def install_dependencies_hdfs():
  logging.info("Installing dependencies for Apache HDFS")
  install_stackable_operator("zookeeper")


def install_dependencies_druid():
  logging.info("Installing dependencies for Druid")
  install_stackable_operator("zookeeper")
  install_stackable_operator("hdfs")
  install_stackable_operator("opa")


def install_dependencies_hbase():
  logging.info("Installing dependencies for HBase")
  install_stackable_operator("zookeeper")
  install_stackable_operator("hdfs")


def install_dependencies_kafka():
  logging.info("Installing dependencies for Kafka")
  install_stackable_operator("zookeeper")
  install_stackable_operator("opa")


def install_dependencies_nifi():
  logging.info("Installing dependencies for NiFi")
  install_stackable_operator("zookeeper")
  install_stackable_operator("secret")


def install_dependencies_opa():
  logging.info("Installing dependencies for OPA")


def install_dependencies_superset():
  logging.info("Installing dependencies for Superset")
  args = [
    '--version', '11.0.0',
    '--set', 'auth.username=superset',
    '--set', 'auth.password=superset',
    '--set', 'auth.database=superset'
  ]
  helper_install_helm_release("superset-postgresql", "postgresql", "bitnami", "https://charts.bitnami.com/bitnami", args)


def install_dependencies_spark_k8s():
  logging.info("Installing dependencies for Spark on Kubernetes")
  # helper_install_minio()    # not needed anymore
  # TODO potentially remove this function again
  # TODO maybe remove the minio stuff altogether


def install_dependencies_airflow():
  logging.info("Installing dependencies for Airflow")
  args = [
    '--version', '11.0.0',
    '--set', 'auth.username=airflow',
    '--set', 'auth.password=airflow',
    '--set', 'auth.database=airflow'
  ]
  helper_install_helm_release("airflow-postgresql", "postgresql", "bitnami", "https://charts.bitnami.com/bitnami", args)

  args = [
    '--set', 'auth.password=redis'
  ]
  helper_install_helm_release("airflow-redis", "redis", "bitnami", "https://charts.bitnami.com/bitnami", args)


def install_dependencies_trino():
  install_stackable_operator("opa")
  install_stackable_operator("hive")
  install_stackable_operator("secret")
  helper_install_minio()


def helper_install_minio():
  """Spins up a MinIO instances providing an S3 API for testing purposes"""
  helper_add_helm_repo("minio", "https://operator.min.io")
  release = helper_find_helm_release("minio-operator", "minio-operator")
  if release:
    logging.info(f"MinIO already running release with name [{release['name']}] and chart [{release['chart']}] - skipping installation")
    return

  # MinIO operator chart versions from 4.2.4 to 4.3.5 (which is the latest
  # at the time of writing) seem to be affected by
  # https://github.com/minio/operator/issues/904
  minio_operator_chart_version = "4.2.3"

  minio_values = helper_execute(['helm', 'show', 'values', '--version', minio_operator_chart_version, 'minio/minio-operator'])
  minio_values = re.sub('requestAutoCert:.*', 'requestAutoCert: false', minio_values)
  minio_values = re.sub('servers:.*', 'servers: 1', minio_values)
  minio_values = re.sub('size:.*', 'size: 10Mi', minio_values)
  # Not all clusters name their default StorageClass "standard", including k3d
  minio_values = re.sub('storageClassName:.*', 'storageClassName: null', minio_values)

  logging.info("Installing Helm release from chart [minio-operator] now")
  args = ['helm', 'install', '--version', minio_operator_chart_version, '--generate-name', '--values', '-', 'minio/minio-operator']
  helper_execute(args, minio_values)
  logging.info("Helm release was installed successfully, waiting for MinIO to start")

  logging.info("Waiting for MinIO pod to become available")
  helper_execute(['kubectl', 'wait', '--for=condition=Available', 'deployment', '--selector=app.kubernetes.io/name=minio-operator', '--timeout=5m'])
  # Sadly we can't wait for StatefulSet to become ready, see https://github.com/kubernetes/kubernetes/issues/79606 so we have to watch the Pods
  logging.info("Waiting 15s for MinIO operator to spawn the actual MinIO pods")
  time.sleep(15)
  helper_execute(['kubectl', 'wait', '--for=condition=Ready', 'pod', '--selector=v1.min.io/tenant=minio1', '--timeout=10m'])
  logging.info("MinIO pod(s) now available - continuing")

  logging.info("Creating MinIO service now and wait 30s until it is available")
  helper_execute(['kubectl', 'apply', '-f', '-'], MINIO_SERVICE)
  time.sleep(30)
  logging.info("MinIO service created")

  minio_node_ip = helper_execute(['kubectl', 'get', 'pod', '--selector=v1.min.io/tenant=minio1', '--output=jsonpath={.items[0].status.hostIP}'])

  minio_node_port = helper_execute(['kubectl', 'get', 'service', 'minio-external', '--output=jsonpath={.spec.ports[0].nodePort}'])

  s3_endpoint = f"http://{minio_node_ip}:{minio_node_port}"
  s3_access_key = helper_execute(['kubectl', 'get', 'secret', 'minio1-secret', '--output=jsonpath="{.data.accesskey}"'])
  s3_secret_key = helper_execute(['kubectl', 'get', 'secret', 'minio1-secret', '--output=jsonpath="{.data.secretkey}"'])

  logging.info("!!!! Make sure the following variables are set in your environment before running")
  logging.info("!!!! the trino integration tests.")
  logging.info(f'export S3_ENDPOINT="{s3_endpoint}"')
  logging.info(f'export S3_ACCESS_KEY={s3_access_key}')
  logging.info(f'export S3_SECRET_KEY={s3_secret_key}')


def helper_install_helm_release(name: str, chart_name: str, repo_name: str = None, repo_url: str = None, install_args: list = None):
  if repo_name and repo_url:
    repo_name = helper_add_helm_repo(repo_name, repo_url)

  release = helper_find_helm_release(name, chart_name)
  if release:
    logging.info(f"Helm already running release with name [{release['name']}] and chart [{release['chart']}] - will not take any further action for this release")
    return

  logging.debug(f"No Helm release with the name {name} found")
  logging.info(f"Installing Helm release [{name}] from chart [{chart_name}] now")
  args = ['helm', 'install', name, f"{repo_name}/{chart_name}"]
  if install_args:
    args = args + install_args
  helper_execute(args)
  logging.info("Helm release was installed successfully")


def helper_find_helm_release(name: str, chart_name: str) -> dict:
  """ This tries to find a Helm release with an _exact_ name like the passed in parameter OR with a chart that _contains_ the passed in chart name.

  The returned object is a dict with these fields in Helm 3.7 (or None if not found): name, namespace, revision, updated, status, chart, app_version
  """
  logging.debug(f"Looking for helm release with chart or name of [{name}]")
  output = json.loads(helper_execute(['helm', 'ls', '-o', 'json']))
  return next((item for item in output if item['name'] == name or chart_name in item['chart']), None)


def helper_command_exists(command: str):
  """ This will check (using `which`) whether the given command exists.
  If not we'll exit the program.
  """
  if shutil.which(command) is None:
    logging.error(f"This script uses '{command}' but it could not be found - please install and try again")
    sys.exit(1)
  logging.debug(f"'{command}' seems to be available - continuing")


def helper_execute(args, stdin: str = None) -> str:
  """ This will execute the passed in program and exit the program if it failed.

  In case of a failure or if debug is enabled it will also print the stdout of the program, stderr is always streamed.
  In case of success it will return the stdout.
  """
  args_string = " ".join(args)
  logging.debug("Running now: " + args_string)
  output = subprocess.run(
    args,
    stdout=subprocess.PIPE,
    input=stdin,
    text=True
  )

  if output.returncode == 0:
    logging.debug('Successfully ran: ' + args_string)
    if output.stdout:
      logging.debug("Output of the program:")
      logging.debug("\n>>>>>>>>>>>>>>>>>>>>>>>\n" + output.stdout.strip("\n") + "\n<<<<<<<<<<<<<<<<<<<<<<<")
    return output.stdout

  logging.error('Error running: ' + args_string)
  if output.stdout:
    logging.error("Output of the program:")
    logging.error("\n>>>>>>>>>>>>>>>>>>>>>>>\n" + output.stdout.strip("\n") + "\n<<<<<<<<<<<<<<<<<<<<<<<")
  sys.exit(1)


class OperatorVersion:
  def __init__(self, name: str, version: str) -> None:
      self.name=name
      self.version=version

  def __format__(self, __format_spec: str) -> str:
      if self.version:
        return f"{self.name}={self.version}"
      else:
        return self.name

  def __repr__(self) -> str:
      if self.version:
        return f"OperatorVersion({self.name}, {self.version})"
      else:
        return f"OperatorVersion({self.name}, None)"


def operator_from_input(input: str) -> OperatorVersion:
    parts = input.split("=")
    if len(parts) == 1 and parts[0] in VALID_OPERATORS:
      result = OperatorVersion(parts[0], None)
      return result
    elif len(parts) == 2 and parts[0] in VALID_OPERATORS:
      result = OperatorVersion(parts[0], parts[1])
      return result
    raise argparse.ArgumentTypeError(f"Operator name {input} is invalid")

def main() -> int:
  args = check_args()
  check_prerequisites()
  if args.kind:
    create_kind_cluster(args.kind)
  check_kubernetes_available()

  # Iterate over all provided operators, parse version from provided string (if there is one)
  for ov in args.operator:
    install_stackable_operator(ov.name, ov.version)
    if args.example:
      install_examples(ov.name)
  logging.info(f"Successfully installed operator for {args.operator}")
  if args.provision:
    helper_execute(['kubectl', 'apply', '-f', args.provision])
    logging.info(f"Successfully applied resources from [{args.provision}]")
  if args.prometheus:
    install_prometheus()
  return 0


if __name__ == '__main__':
  sys.exit(main())
