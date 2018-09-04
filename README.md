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

Options:
    --aws-access-key ACCESS_KEY   AWS access key ID (default: $AWS_ACCESS_KEY_ID)
    --aws-secret-key SECRET_KEY   AWS secret access key (default: $AWS_SECRET_ACCESS_KEY)
    --kubectl PATH                specify path to kubectl (default: $PATH)
    --kube-config PATH            Kubernetes config path (default: $KUBECONFIG)
    --kube-server ADDRESS         Kubernetes API server address (default: $KUBE_SERVER)
    --kube-ca DATA                Kubernetes certificate authority data (default: $KUBE_CA)
    --kube-token TOKEN            Kubernetes access token (default: $KUBE_TOKEN)
    --max-age DURATION            Maximum age of server before draining and terminating. (default: 3d) (default: $MAX_AGE)
    --max-nodes COUNT             drain maximum of COUNT nodes per cycle (default: $MAX_NODES_COUNT, or 1)
    --every SCHEDULE              run periodically, example: --every 1h (default: $CHECK_PERIOD)
    --dry-run                     perform a dry-run, doesn't drain terminate any instances. (default: $DRY_RUN)
    -h, --help                    print help
```

You can use the `--every` option to let the program do its own scheduling or deploy it as a [cron job](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/).

## Development

Most of the code is in [bin/k8s-aws-detox](bin/k8s-aws-detox).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kontena/k8s-aws-detox

