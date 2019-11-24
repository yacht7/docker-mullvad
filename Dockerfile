FROM alpine:3.10

LABEL maintainer="yacht7"

ENV REGION=us-ga \
    LOG_LEVEL=3

RUN \
    apk add --no-cache \
        curl \
        openvpn && \
    mkdir /data

COPY scripts/ /data

RUN chmod 500 /data/entry.sh

ENTRYPOINT ["/data/entry.sh"]