#!/usr/bin/env bash
# kubeyard-qsub.sh: fake qsub that just runs kubectl to submit a job
set -ex

# Set some defaults
IMAGE=quay.io/adamnovak/kubeyard:latest
MEMORY="4Gi"
CPU="1"
DISK="50Gi"
NAME_PREFIX="job"

# Set defaults for our environment
# These are mostly for local testing of qsub outside a proper interactive pod.
KUBEYARD_SERVICE_ACCOUNT="${KUBEYARD_SERVICE_ACCOUNT:-vg-svc}"
KUBEYARD_S3_BUCKET="${KUBEYARD_S3_BUCKET:-vg-data}"
KUBEYARD_S3_CREDENTIALS_SECRET="${KUBEYARD_S3_CREDENTIALS_SECRET:-shared-s3-credentials}"
KUBEYARD_OWNING_USER="${KUBEYARD_OWNING_USER:-$(whoami)}"

usage() {
    # Print usage to stderr
    exec 1>&2
    printf "Usage: $0 [OPTIONS] [SCRIPT] \n"
    printf "\nSummary:\n\n"
    printf "\tRun the given script on Kubernetes. If script is missing or \"-\", read \n"
    printf "\tscript from standard input. Outputs the name of the submitted job.\n"
    printf "\nPOSIX Options:\n\n"
    printf "\t-N NAME\tUse the given name for the job\n"
    printf "\nExtra Options:\n\n"
    printf "\t-I IMAGE\tUse the given Docker image. Default: ${IMAGE}\n"
    printf "\t-R MEM\t\tUse the given RAM limit. Default: ${MEMORY}\n"
    printf "\t-P CPU\t\tUse the given number of processors. Default: ${CPU}\n"
    printf "\t-D DISK\t\tUse the given disk space limit. Default: ${DISK}\n"
    exit 1
}

while getopts "N:I:R:P:D:" o; do
    case "${o}" in
        N)
            # Make sure name is lower-case
            NAME_PREFIX="${OPTARG,,}"
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

# Get the script they want us to run
SCRIPT="${1}"
if [[ -z "${SCRIPT}" || "${SCRIPT}" == "-" ]] ; then
    # If it is standard in, read standard in
    SCRIPT="/dev/stdin"
fi
# TODO: if not standard in, use filename in job name

# Compute a probably unique name
JOB_NAME="${KUBEYARD_OWNING_USER}-${NAME_PREFIX}-${RANDOM}-${RANDOM}-${RANDOM}"

# Delete the job if it exists
kubectl delete job ${JOB_NAME} 2>/dev/null || true
# Then make it
kubectl apply -f - >/dev/null <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: ${JOB_NAME}
spec:
  ttlSecondsAfterFinished: 3600
  template:
    spec:
      containers:
      - name: main
        imagePullPolicy: Always
        image: ${IMAGE}
        # We indent the whole script and pass it
        # in a bash command to our entrypoint
        args:
        - /bin/bash
        - -c
        - |
$(cat "${SCRIPT}" | sed 's/^/          /')
        resources:
          limits:
            cpu: "${CPU}"
            memory: "${MEMORY}"
            ephemeral-storage: "${DISK}"
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
      serviceAccountName: "${KUBEYARD_SERVICE_ACCOUNT}"
  backoffLimit: 0
EOF

# Report the job name
echo "${JOB_NAME}"
