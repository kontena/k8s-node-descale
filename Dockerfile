FROM ruby:2.5-alpine3.7 as builder
MAINTAINER Kontena, Inc. <info@kontena.io>

WORKDIR /app
COPY . .
RUN gem build k8s_aws_detox.gemspec && \
    gem install --no-document k8s_aws_detox*.gem && \
    rm -rf /app
USER nobody
CMD ["k8s-aws-detox"]
