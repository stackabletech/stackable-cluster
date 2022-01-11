FROM openjdk:11-jre-slim
LABEL maintainer="Stackable GmbH"

RUN apt update && \
    apt install -y curl unzip && \
    cd /tmp && \
    curl -O https://downloads.gradle-dn.com/distributions/gradle-7.3.3-bin.zip && \
    unzip gradle-*.zip && \
    mkdir /opt/gradle && \
    cp -pr gradle-*/* /opt/gradle && \
    echo "export PATH=/opt/gradle/bin:${PATH}" | tee /etc/profile.d/gradle.sh && \
    chmod +x /etc/profile.d/gradle.sh && \
    source /etc/profile.d/gradle.sh


#WORKDIR /stackable

#COPY spark /stackable


