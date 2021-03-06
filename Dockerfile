FROM ruby:2.5-alpine3.7
MAINTAINER Kontena, Inc. <info@kontena.io>

ARG KUBE_VERSION=1.11.1

WORKDIR /app
COPY . .
ADD https://storage.googleapis.com/kubernetes-release/release/v${KUBE_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl && \
    apk --update add build-base && \
    gem build k8s_node_descale.gemspec && \
    gem install --no-document k8s_node_descale*.gem && \
    apk del build-base && \
    rm -rf /app
USER nobody
CMD ["k8s-node-descale"]
