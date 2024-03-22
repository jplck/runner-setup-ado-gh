# Based on: https://testdriven.io/blog/github-actions-docker/

FROM ubuntu:latest

ARG RUNNER_VERSION="2.314.1"

RUN apt-get update -y && apt-get upgrade -y
RUN useradd -m docker

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
curl jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip

RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && rm ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && chown -R docker /home/docker/actions-runner

RUN /home/docker/actions-runner/bin/installdependencies.sh

COPY ./start.sh ./
RUN chmod +x ./start.sh

USER docker

ENTRYPOINT ./start.sh