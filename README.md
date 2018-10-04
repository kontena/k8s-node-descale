# k8s-node-descale

Drains Kubernetes nodes after they reach the specified best-before age. To be used together with an autoscaler so that the node will get replaced with a fresh one when there is demand.

## Installation

### Building manually:

```
$ gem build k8s_node_descale.gemspec
$ gem install k8s_node_desacale*.gem
$ k8s-node-descale
```

### Docker:

```
$ docker build -t descale --build-arg KUBE_VERSION=1.11.1 .
$ docker run -t descale
```

### Docker Compose:

```
$ KUBE_VERSION=1.11.1 docker-compose run -rm
```

## Usage

### Command-line help

```
Usage:
    k8s-node-descale [OPTIONS]

  Drains Kubernetes nodes after they reach the specified best-before date.

Options:
    --kubectl PATH                specify path to kubectl (default: $PATH)
    --kube-config PATH            Kubernetes config path (default: $KUBECONFIG)
    --kube-server ADDRESS         Kubernetes API server address (default: $KUBE_SERVER)
    --kube-ca DATA                Kubernetes certificate authority data (default: $KUBE_CA)
    --kube-token TOKEN            Kubernetes access token (default: $KUBE_TOKEN)
    --max-age DURATION            maximum age of server before draining and terminating (default: $MAX_AGE, or "3d")
    --max-nodes COUNT             drain maximum of COUNT nodes per cycle (default: $MAX_NODES_COUNT, or 1)
    --check-period SCHEDULE       run periodically, example: --every 1h (default: $CHECK_PERIOD)
    --dry-run                     perform a dry-run, doesn't drain or terminate any instances. (default: $DRY_RUN, or false)
    -h, --help                    print help
```

### Scheduling

You can use the `--check-period` option to let the program do its own scheduling or deploy it as a [cron job](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/).

### Configuring credentials

#### Kube API

The Kubernetes credentials lookup order is:

- `--kube-config` option or `KUBECONFIG` environment variable
- `--kube-server`, `--kube-token` and `--kube-ca` options or `KUBE_SERVER`, `KUBE_TOKEN` and `KUBE_CA` environment variables
- `~/.kube/config` configuration file
- `/etc/kubernetes/admin.conf` configuration file
- "in-cluster-configuration" when running on a Kubernetes node (`KUBERNETES_SERVICE_HOST` and `KUBERNETES_SERVICE_PORT_HTTPS` environment variables, `/var/run/secrets/kubernetes.io/serviceaccount/ca.crt` and `/var/run/secrets/kubernetes.io/serviceaccount/token` configuration files)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kontena/k8s-node-descale

