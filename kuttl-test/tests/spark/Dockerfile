FROM openjdk:11-jre-slim
LABEL maintainer="Stackable GmbH"

ARG GRADLE_VERSION=7.3.3
ARG GRADLE_BASE_URL=https://services.gradle.org/distributions
ARG GRADLE_SHA=b586e04868a22fd817c8971330fec37e298f3242eb85c374181b12d637f80302

RUN apt update && \
    apt install -y curl unzip && \
    mkdir -p /usr/share/gradle /usr/share/gradle/ref && \
    \
    echo "Downloading gradle hash" && \
    curl -fsSL -o /tmp/gradle.zip ${GRADLE_BASE_URL}/gradle-${GRADLE_VERSION}-bin.zip && \
    \
    echo "Checking download hash" && \
    echo "${GRADLE_SHA}  /tmp/gradle.zip" | sha256sum -c - && \
    \
    echo "Unziping gradle" && \
    unzip -d /usr/share/gradle /tmp/gradle.zip && \
    \
    echo "Cleaning and setting links" && \
    rm -f /tmp/gradle.zip && \
    ln -s /usr/share/gradle/gradle-${GRADLE_VERSION} /usr/bin/gradle


#RUN mkdir /opt/gradle && \
#    cp -pr gradle-*/* /opt/gradle
#echo ${GRADLE_BASE_URL}"/gradle-"${GRADLE_VERSION}"-bin.zip" && \
#ENV GRADLE_HOME=/opt/gradle/gradle-7.3.3
#ENV PATH=$PATH:$GRADLE_HOME/bin


    #export PATH=$PATH:/opt/gradle/gradle-7.3.3/bin
    #echo "export PATH=/opt/gradle/bin:${PATH}" | tee /etc/profile.d/gradle.sh && \
    #chmod +x /etc/profile.d/gradle.sh

#RUN ["/bin/bash", "-c", "/etc/profile.d/gradle.sh"]



COPY /minimalSpark/* /stackable/minimalSpark/

ENV GRADLE_VERSION 7.3.3
ENV GRADLE_HOME /usr/bin/gradle
ENV GRADLE_USER_HOME /cache

ENV PATH $PATH:$GRADLE_HOME/bin

VOLUME $GRADLE_USER_HOME

#RUN gradle --version

#CMD [""]
