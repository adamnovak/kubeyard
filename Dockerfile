# This is the Dockerfile for the interactive host

FROM ubuntu:19.10

RUN DEBIAN_FRONTEND=noninteractive apt-get -q -y update && \
    (yes | DEBIAN_FRONTEND=noninteractive unminimize) && \
    DEBIAN_FRONTEND=noninteractive apt-get -q -y upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get -q -y install \
        python3-pip \
        python3-virtualenv \
        libcurl4-gnutls-dev \
        python3-dev \
        uuid-runtime \
        awscli \
        jq \
        s3fs \
        golang-1.12 \
        git \
        build-essential \
        curl \
        wget \
        bash-completion && \
    DEBIAN_FRONTEND=noninteractive apt-get clean
    
# Get kubectl so we can talk to Kubernetes and sniff out secrets
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kubectl && \
  chmod +x ./kubectl && \
  mv ./kubectl /usr/local/bin/kubectl
  
# Install its completions for everyone
RUN echo ". /etc/bash_completion ; . <(/usr/local/bin/kubectl completion bash)" >>/etc/bash.bashrc
  
# Add a script which will set up an s3fs mount
ADD ./src/kubeyard-entrypoint.sh /usr/local/bin/kubeyard-entrypoint.sh
RUN chmod +x /usr/local/bin/kubeyard-entrypoint.sh

# Add our own hacky Kubernetes qsub that can run more of ourselves with our S3 mount
ADD ./src/kubeyard-qsub.sh /usr/local/bin/qsub
RUN chmod +x /usr/local/bin/qsub

# Container will expect these environment variables:
#
# Service account to run stuff as
# KUBEYARD_SERVICE_ACCOUNT="vg-svc"
#
# Bucket to try to mount as /s3
# KUBEYARD_S3_BUCKET="vg-data"
#
# Kubernetes secret containing `credentials` file for AWS
# KUBEYARD_S3_CREDENTIALS_SECRET="shared-s3-credentials"
#
# Name of the user who should own all the pods
# KUBEYARD_OWNING_USER="$(whoami)"

ENTRYPOINT ["/usr/local/bin/kubeyard-entrypoint.sh"]

