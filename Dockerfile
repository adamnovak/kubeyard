# This is the Dockerfile for the interactive host

FROM ubuntu:19.10

RUN DEBIAN_FRONTEND=noninteractive apt-get -q -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get -q -y upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get -q -y install \
        python-pip \
        python-virtualenv \
        libcurl4-gnutls-dev \
        python3-dev \
        libssl1.0-dev \
        uuid-runtime \
        awscli \
        jq \
        s3fs \
        golang-1.12 \
        git \
        build-essential && \
    DEBIAN_FRONTEND=noninteractive sudo apt-get clean

# Get kubectl so we can talk to Kubernetes and sniff out secrets
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kubectl && \
  chmod +x ./kubectl && \
  mv ./kubectl /usr/local/bin/kubectl
  
# Get Kubernetes qsub so we can submit jobs HPC-style
RUN curl -LO https://github.com/dgruber/qsub/raw/master/builds/qsub_linux && \
  chmod +x ./qsub_linux && \
  mv ./qsub_linux /usr/local/bin/qsub

# Add a script which will set up an s3fs mount
ADD ./kubeyard-entrypoint.sh /usr/local/bin/kubeyard-entrypoint.sh
RUN chmod +x /usr/local/bin/kubeyard-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/kubeyard-entrypoint.sh"]

