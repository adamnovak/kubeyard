#!/usr/bin/env bash
# stop.sh: tear down a running Kubeyard pod for the current user, if present
set -e

# Figure out who we are
KUBEYARD_OWNING_USER="${KUBEYARD_OWNING_USER:-$(whoami)}"

# Work out the pod name to use
POD_NAME="${KUBEYARD_OWNING_USER}-kubeyard"

# Delete it, or complain if it doesn't exist.
kubectl delete pod "${POD_NAME}"
