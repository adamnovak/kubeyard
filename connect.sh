#!/usr/bin/env bash
# connect.sh: connect to a running Kubeyard pod for the current user, if present
set -e

# Figure out who we are
KUBEYARD_OWNING_USER="${KUBEYARD_OWNING_USER:-$(whoami)}"

# Work out the pod name to use
POD_NAME="${KUBEYARD_OWNING_USER}-kubeyard"

# Connect to it and open a shell
kubectl exec -ti "${POD_NAME}" -- /bin/bash
