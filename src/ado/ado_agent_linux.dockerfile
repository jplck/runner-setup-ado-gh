FROM alpine

RUN apk update
RUN apk upgrade
RUN apk add bash curl git icu-libs jq

ENV TARGETARCH="linux-musl-x64"

WORKDIR /azp/

COPY ./start.sh ./
RUN chmod +x ./start.sh

RUN adduser -D agent
RUN chown agent ./
USER agent

ENTRYPOINT ./start.sh