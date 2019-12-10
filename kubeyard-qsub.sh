#!/usr/bin/env bash
# kubeyard-qsub.sh: fake qsub that just runs kubectl to submit a job

# Set some defaults
IMAGE=quay.io/adamnovak/kubeyard:latest
DISK="50Gi"
MEMORY="4Gi"
CPU="1"
SERVICE_ACCOUNT="${KUBEYARD_SERVICE_ACCOUNT}"
BUCKET="${KUBEYARD_S3_BUCKET}"

# Good option parsing. See <https://stackoverflow.com/a/28466267>
while getopts "i:d:m:c:" ARG; do
    case "${ARG}" in
    i) IMAGE="${OPTARG}" ;;
    d) DISK="${OPTARG}" ;;
    m) MEMORY="${OPTARG}" ;;
    m) CPU="${OPTARG}" ;;
    -)
        LONG_OPTARG="${OPTARG#*=}"
        case "${OPTARG}" in
        image=?*)
            IMAGE="${LONG_OPTARG}" ;;
        image)
            eval "IMAGE=\"\$$OPTIND\""
            if [ -z "${IMAGE}" ]; then
                echo "No arg for --$OPTARG option" >&2
                exit 2
            fi
            OPTIND=$((OPTIND+1)) ;;
        disk=?*)
            DISK="${LONG_OPTARG}" ;;
        disk)
            eval "DISK=\"\$$OPTIND\""
            if [ -z "${DISK}" ]; then
                echo "No arg for --$OPTARG option" >&2
                exit 2
            fi
            OPTIND=$((OPTIND+1)) ;;
        memory=?*)
            MEMORY="${LONG_OPTARG}" ;;
        memory)
            eval "MEMORY=\"\$$OPTIND\""
            if [ -z "${MEMORY}" ]; then
                echo "No arg for --$OPTARG option" >&2
                exit 2
            fi
            OPTIND=$((OPTIND+1)) ;;
        cpu=?*)
            CPU="${LONG_OPTARG}" ;;
        cpu)
            eval "CPU=\"\$$OPTIND\""
            if [ -z "${CPU}" ]; then
                echo "No arg for --$OPTARG option" >&2
                exit 2
            fi
            OPTIND=$((OPTIND+1)) ;;
        '')
            break ;; # "--" terminates argument processing
        * )
            echo "Illegal option --$OPTARG" >&2; exit 2 ;;
        esac ;;
    \? ) exit 2 ;;  # getopts already reported the illegal option
    esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

JOB_NAME="$(whoami)-job-${RANDOM}-${RANDOM}-${RANDOM}"

ARGS=( "$@" )
# Collect all the arguments as comma-separated double-quoted strings.
# TODO: We don't do any escaping of internal quotes! How do we yaml-escape in bash?
CSV_ARGS=""
for ARG in "${ARGS[@]}" ; do
    CSV_ARGS="${CSV_ARGS},\"${ARG}\""
done
# Drop elading comma
CSV_ARGS="${CSV_ARGS#,}"

if [[ -z "${CSV_ARGS}" ]] ; then
    echo "Please specify a command to run." >&2
    exit 2
fi

function join_and_quote {
    local IFS=",";
    shift;
    echo "$*";
}

kubectl delete job ${JOB_NAME} 2>/dev/null
kubectl apply -f - <<EOF
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
        args: [${CSV_ARGS}]
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
          value: ${SERVICE_ACCOUNT}
        - name: KUBEYARD_S3_BUCKET
          value: ${BUCKET}
      restartPolicy: Never
      serviceAccountName: ${SERVICE_ACCOUNT}
  backoffLimit: 0
EOF
