#!/usr/bin/env bash
# start.sh: make an itneractive node to submit jobs from
set -e

# Set some defaults
IMAGE=quay.io/adamnovak/kubeyard:latest
MEMORY="2Gi"
CPU="1"
DISK="5Gi"

# Set defaults for our environment
KUBEYARD_SERVICE_ACCOUNT="${KUBEYARD_SERVICE_ACCOUNT}"
KUBEYARD_S3_BUCKET="${KUBEYARD_S3_BUCKET}"
KUBEYARD_S3_CREDENTIALS_SECRET="${KUBEYARD_S3_CREDENTIALS_SECRET}"
KUBEYARD_OWNING_USER="${KUBEYARD_OWNING_USER:-$(whoami)}"

usage() {
    # Print usage to stderr
    exec 1>&2
    printf "Usage: $0 [OPTIONS]\n"
    printf "\nSummary:\n\n"
    printf "\tCreate an interactive pod to work in. Outputs the pod name.\n"
    printf "\nOptions:\n\n"
    printf "\t-a ACCOUNT\tUse the given service account in the pod. Default: ${KUBEYARD_SERVICE_ACCOUNT}\n"
    printf "\t-b BUCKET\tMount the given S3 bucket as /s3. Default: ${KUBEYARD_S3_BUCKET}\n"
    printf "\t-s SECRET\tUse the given secret for AWS access. Default: ${KUBEYARD_S3_CREDENTIALS_SECRET}\n"
    printf "\t-I IMAGE\tUse the given Docker image. Default: ${IMAGE}\n"
    printf "\t-R MEM\t\tUse the given RAM limit. Default: ${MEMORY}\n"
    printf "\t-P CPU\t\tUse the given number of processors. Default: ${CPU}\n"
    printf "\t-D DISK\t\tUse the given disk space limit. Default: ${DISK}\n"
    exit 1
}

while getopts "a:b:s:I:R:P:D:" o; do
    case "${o}" in
        a)
            KUBEYARD_SERVICE_ACCOUNT="${OPTARG}"
            ;;
        b)
            KUBEYARD_S3_BUCKET="${OPTARG}"
            ;;
        s)
            KUBEYARD_S3_CREDENTIALS_SECRET="${OPTARG}"
            ;;
        I)
            IMAGE="${OPTARG}"
            ;;
        R)
            MEMORY="${OPTARG}"
            ;;
        P)
            CPU="${OPTARG}"
            ;;
        D)
            DISK="${OPTARG}"
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# Make sure we have all the settings we need.
if [[ -z "${KUBEYARD_SERVICE_ACCOUNT}" ]] ; then
    echo "Set \$KUBEYARD_SERVICE_ACCOUNT or specify -a" 1>&2
    exit 1
fi

if [[ -z "${KUBEYARD_S3_BUCKET}" ]] ; then
    echo "Set \$KUBEYARD_S3_BUCKET or specify -b" 1>&2
    exit 1
fi

if [[ -z "${KUBEYARD_S3_CREDENTIALS_SECRET}" ]] ; then
    echo "Set \$KUBEYARD_S3_CREDENTIALS_SECRET or specify -s" 1>&2
    exit 1
fi

# Work out the pod name to use
POD_NAME="${KUBEYARD_OWNING_USER}-kubeyard"

# There should only be one pod per user, so clean it up if it exists.
kubectl delete pod ${POD_NAME} 2>/dev/null >/dev/null || true

# Then make it
kubectl apply -f - >/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: "${POD_NAME}"
spec:
  containers:
  - name: main
    imagePullPolicy: Always
    image: "${IMAGE}"
    # Keep the entrypoint from the image
    # Make the pod sit forever
    args: ["sleep", "infinity"]
    resources:
      limits:
        cpu: "${CPU}"
        memory: "${MEMORY}"
        ephemeral-storage: "${DISK}"
    # Needs to be privileged to mount S3 with FUSE
    securityContext:
      privileged: true
      capabilities:
        add:
        - SYS_ADMIN
    env:
    - name: KUBEYARD_SERVICE_ACCOUNT
      value: "${KUBEYARD_SERVICE_ACCOUNT}"
    - name: KUBEYARD_S3_BUCKET
      value: "${KUBEYARD_S3_BUCKET}"
    - name: KUBEYARD_S3_CREDENTIALS_SECRET
      value: "${KUBEYARD_S3_CREDENTIALS_SECRET}"
    - name: KUBEYARD_OWNING_USER
      value: "${KUBEYARD_OWNING_USER}"
  restartPolicy: Never
  serviceAccountName: ${KUBEYARD_SERVICE_ACCOUNT}
EOF

# Report the job name
echo "Created pod ${POD_NAME}"
