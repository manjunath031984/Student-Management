# Custom Jenkins controller: Java 17 + Apache Maven 3.5.4 (exact).
FROM jenkins/jenkins:lts-jdk17

USER root

ARG MAVEN_VERSION=3.5.4
ARG TERRAFORM_VERSION=1.13.5
ARG NODE_MAJOR=22

# Base image ships Temurin 17 here. Do not install another JDK.
ENV JAVA_HOME=/opt/java/openjdk
ENV MAVEN_HOME=/opt/maven
ENV PATH="${MAVEN_HOME}/bin:${JAVA_HOME}/bin:/usr/local/bin:${PATH}"
ENV GODEBUG=tlsmlkem=0,tlskyber=0,http2client=0

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         ca-certificates \
         curl \
         git \
         gnupg \
         jq \
         lsb-release \
         unzip \
         apt-transport-https \
         openssl \
    && update-ca-certificates \
    && sed -i '/^\[openssl_init\]$/a ssl_conf = ssl_sect' /etc/ssl/openssl.cnf \
    && printf '%s\n' \
         '' \
         '[ssl_sect]' \
         'system_default = system_default_sect' \
         '' \
         '[system_default_sect]' \
         'MinProtocol = TLSv1.2' \
         'MaxProtocol = TLSv1.3' \
         'Groups = X25519:P-256:P-384' \
         >> /etc/ssl/openssl.cnf \
    && printf '%s\n' 'GODEBUG=tlsmlkem=0,tlskyber=0,http2client=0' >> /etc/environment \
    && rm -rf /var/lib/apt/lists/*

# Apache Maven 3.5.4 only — never use the distro Maven package.
RUN curl -fsSL \
      "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
      -o /tmp/apache-maven.tar.gz \
    && mkdir -p /opt \
    && tar -xzf /tmp/apache-maven.tar.gz -C /opt \
    && rm -f /tmp/apache-maven.tar.gz \
    && mv "/opt/apache-maven-${MAVEN_VERSION}" /opt/maven \
    && ln -sfn /opt/maven/bin/mvn /usr/local/bin/mvn \
    && ln -sfn /opt/java/openjdk/bin/java /usr/local/bin/java \
    && test -x /opt/maven/bin/mvn

# Docker CLI from the official static tarball (avoids Debian-codename apt repos).
ARG DOCKER_CLI_VERSION=29.5.3
ARG BUILDX_VERSION=0.26.1
RUN curl -fsSL \
      "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VERSION}.tgz" \
      -o /tmp/docker.tgz \
    && tar -xzf /tmp/docker.tgz -C /tmp \
    && mv /tmp/docker/docker /usr/local/bin/docker \
    && chmod +x /usr/local/bin/docker \
    && rm -rf /tmp/docker /tmp/docker.tgz \
    && mkdir -p /usr/local/lib/docker/cli-plugins /usr/libexec/docker/cli-plugins \
    && curl -fsSL \
         "https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-amd64" \
         -o /usr/local/lib/docker/cli-plugins/docker-buildx \
    && chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx \
    && ln -sfn /usr/local/lib/docker/cli-plugins/docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx \
    && groupadd -f docker \
    && usermod -aG docker jenkins \
    && usermod -aG root jenkins

# Terraform 1.13.x (image default; pipeline must not install another Java/Maven).
RUN curl -fsSL \
      "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
      -o /tmp/terraform.zip \
    && unzip -o /tmp/terraform.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/terraform \
    && rm -f /tmp/terraform.zip

# Google Cloud CLI + GKE auth plugin.
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
         > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
         google-cloud-cli \
         google-cloud-cli-gke-gcloud-auth-plugin \
    && rm -rf /var/lib/apt/lists/*

# kubectl (client).
RUN curl -fsSLo /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl

# Node.js LTS for frontend npm ci / lint / build (pipeline requirement).
RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Fail the image build unless Java 17 + Maven 3.5.4 are what `java`/`mvn` resolve to.
RUN printf '%s\n' \
      'export JAVA_HOME=/opt/java/openjdk' \
      'export MAVEN_HOME=/opt/maven' \
      'export PATH="/opt/maven/bin:/opt/java/openjdk/bin:/usr/local/bin:${PATH}"' \
      > /etc/profile.d/java-maven.sh \
    && chmod 644 /etc/profile.d/java-maven.sh \
    && echo "JAVA_HOME=${JAVA_HOME}" \
    && test -n "${JAVA_HOME}" \
    && test -x "${JAVA_HOME}/bin/java" \
    && java -version 2>&1 | grep -E 'version "17(\.|$)' \
    && mvn -version | grep -F "Apache Maven 3.5.4" \
    && mvn -version | grep -E "Java version: 17(\.|$)" \
    && test -x /opt/maven/bin/mvn \
    && test -x /usr/local/bin/java \
    && test -x /opt/maven/bin/mvn

USER jenkins

# Keep the same toolchain for the Jenkins controller process.
ENV JAVA_HOME=/opt/java/openjdk
ENV MAVEN_HOME=/opt/maven
ENV PATH="/opt/maven/bin:/opt/java/openjdk/bin:/usr/local/bin:${PATH}"
# TLS 1.2+ with X25519. Do not disable certificate verification.
ENV GODEBUG=tlsmlkem=0,tlskyber=0,http2client=0
