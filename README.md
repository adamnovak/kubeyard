# kubeyard: Courtyard for Kubernetes

To make a pod to work in:

```
# Change this to the service account appropriate to your namespace
export KUBEYARD_SERVICE_ACCOUNT=vg-svc
# Change this to the S3 bucket you use
export KUBEYARD_S3_BUCKET=vg-k8s
# We also support a KUBEYARD_S3_CREDENTIALS_SECRET

# Then run this
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $(whoami)-kubeyard
spec:
  containers:
  - name: main
    imagePullPolicy: Always
    image: quay.io/adamnovak/kubeyard:latest
    # Keep the entrypoint from the image
    args: ["sleep", "infinity"]
    resources:
      limits:
        cpu: 1
        memory: "2Gi"
        ephemeral-storage: "2Gi"
    securityContext:
      privileged: true
      capabilities:
        add:
        - SYS_ADMIN
    env:
    - name: KUBEYARD_SERVICE_ACCOUNT
      value: ${KUBEYARD_SERVICE_ACCOUNT}
    - name: KUBEYARD_S3_BUCKET
      value: ${KUBEYARD_S3_BUCKET}
  restartPolicy: Never
  serviceAccountName: ${KUBEYARD_SERVICE_ACCOUNT}
EOF
```

To connect to your pod:

```
kubectl exec -ti $(whoami)-kubeyard -- /bin/bash
```

Once in the pod, the bucket you specified is mounted at `/s3`:

```
ls /s3
```

To run a command against that filesystem in another pod use `qsub`:

```
qsub touch /s3/users/whoever/test.txt
```

To tear down your pod:

```
kubectl delete pod $(whoami)-kubeyard 
```

