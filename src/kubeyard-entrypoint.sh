#!/usr/bin/env bash
# kubeyard-entrypoint.sh: mount AWS S3 as a shared filesystem and configure qsub to also expose it

# Download AWS credential file secret
mkdir -p ~/.aws
kubectl get secret -o json "${KUBEYARD_S3_CREDENTIALS_SECRET}" | jq -r '.data.credentials' | base64 -d > ~/.aws/credentials
chmod 600 ~/.aws/credentials

# Compose credentials file in s3fs format
# TODO: If your config file isn't very simple this will not work.
AWS_ACCESS_KEY="$(cat ~/.aws/credentials | grep -v "^\s*#" | grep aws_access_key_id | head -n1 | cut -f2 -d'=' | tr -d ' ')"
AWS_SECRET_KEY="$(cat ~/.aws/credentials | grep -v "^\s*#" | grep aws_secret_access_key | head -n1 | cut -f2 -d'=' | tr -d ' ')"
echo "${AWS_ACCESS_KEY}:${AWS_SECRET_KEY}" >/etc/passwd-s3fs
chmod 600 /etc/passwd-s3fs

# Mount the bucket
echo "s3fs#${KUBEYARD_S3_BUCKET} /s3 fuse _netdev,allow_other 0 0" >> /etc/fstab
mkdir -p /s3
mount /s3

# Run whatever we were supposed to run
exec "$@"
