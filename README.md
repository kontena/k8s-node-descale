# k8s-aws-detox

Drains + terminates AWS EC2 nodes after they reach the specified best-before age. To be used in an [Auto Scaling Group](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html) so that the node will get replaced with a fresh one when there is demand.

## Installation

### Building manually:

```
$ gem build k8s_aws_detox.gemspec
$ gem install k8s_aws_detox*.gem
$ k8s-aws-detox
```

### Docker:

```
$ docker build -t detox --build-arg KUBE_VERSION=1.11.1 .
$ docker run -t detox k8s-aws-detox
```

### Docker Compose:

```
$ KUBE_VERSION=1.11.1 docker-compose run -rm k8s-aws-detox
```

## Usage

### Command-line help

```
Usage:
    k8s-aws-detox [OPTIONS]

  Drains and terminates Kubernetes nodes running in Amazon EC2 after they reach the specified best-before date.

Options:
    --aws-access-key ACCESS_KEY   AWS access key ID (default: $AWS_ACCESS_KEY_ID)
    --aws-secret-key SECRET_KEY   AWS secret access key (default: $AWS_SECRET_ACCESS_KEY)
    --kubectl PATH                specify path to kubectl (default: $PATH)
    --kube-config PATH            Kubernetes config path (default: $KUBECONFIG)
    --kube-server ADDRESS         Kubernetes API server address (default: $KUBE_SERVER)
    --kube-ca DATA                Kubernetes certificate authority data (default: $KUBE_CA)
    --kube-token TOKEN            Kubernetes access token (default: $KUBE_TOKEN)
    --max-age DURATION            maximum age of server before draining and terminating (default: $MAX_AGE, or "3d")
    --max-nodes COUNT             drain maximum of COUNT nodes per cycle (default: $MAX_NODES_COUNT, or 1)
    --check-period SCHEDULE       run periodically, example: --every 1h (default: $CHECK_PERIOD)
    --dry-run                     perform a dry-run, doesn't drain terminate any instances. (default: $DRY_RUN, or false)
    -h, --help                    print help
```

### Scheduling

You can use the `--check-period` option to let the program do its own scheduling or deploy it as a [cron job](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/).

### Configuring credentials

#### AWS

The AWS credentials lookup order is:

- `--aws-access-key` and `--aws-secret-key` options
- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables
- The shared credentials file at `~/.aws/credentials`
- From the instance profile when running on EC2

#### Kube API

The Kubernetes credentials lookup order is:

- `--kube-config` option or `KUBECONFIG` environment variable
- `--kube-server`, `--kube-token` and `--kube-ca` options
- `~/.kube/config` configuration file
- `/etc/kubernetes/admin.conf` configuration file
- "in-cluster-configuration" when running on a Kubernetes node (`KUBERNETES_SERVICE_HOST` and `KUBERNETES_SERVICE_PORT_HTTPS` environment variables, `/var/run/secrets/kubernetes.io/serviceaccount/ca.crt` and `/var/run/secrets/kubernetes.io/serviceaccount/token` configuration files)

## Development

Most of the code is in [bin/k8s-aws-detox](bin/k8s-aws-detox).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kontena/k8s-aws-detox

