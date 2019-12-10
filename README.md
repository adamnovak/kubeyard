# kubeyard: Courtyard for Kubernetes

This repository contains some scripts and describes an associated Docker image that let you use Kubernetes in a more HPC-like fashion, like the UCSC Genomics Insititute's Courtyard and Plaza shared machines.

## Usage

To make an interactive pod to work in:

```
# Specify Kubernetes service account, S3 bucket name, and S3 credentials secret name
./start.sh -a vg-svc -b vg-k8s -s shared-s3-credentials
```

To connect to your pod and get an interactive shell session, you can run:
```
./connect.sh
```

Once in the pod, the bucket you specified is mounted at `/s3`. To inspect it, you can run:
```
ls /s3
```

Within thYour interactive pod has very low resource limits. To run a command as a job, use `qsub` on a script file or standard input from inside your pod. The job will also have the `/s3` mount available:
```
echo "ls -lah /s3" | qsub -
```
The `qsub` command will print the name of the submitted job. The `qsub` command can also take memory, disk, and CPU limits for the job as options.

Finally, when you are done, you can tear down your interactive pod from your local machine:
```
./stop.sh
```

## Environment Variables

You can set the following environment variables to set defaults or overrides for some parameters:

* `KUBEYARD_SERVICE_ACCOUNT`: Set the Kubernetes service account to use.
* `KUBEYARD_S3_BUCKET`: Set the S3 bucket name to mount.
* `KUBEYARD_S3_CREDENTIALS_SECRET`: Set the name of the Kubernetes secret containing the AWS `config` file to pull credentials from. The config file must contain exactly one line with `aws_access_key_id` in it, and exactly one line with `aws_secret_access_key` in it, in addition to being a valid `awscli` config file.
* `KUBEYARD_OWNING_USER`: Override the user name prefixed onto job and pod names. The default is login name of the current user.
