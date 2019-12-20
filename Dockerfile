FROM alpine:3.10

LABEL maintainer="yacht7"

ENV REGION=us-ga \
    SUBNETS=192.168.0.0/24 \
    LOG_LEVEL=3

RUN \
    apk add --no-cache \
        curl \
        openvpn && \
    mkdir /data
COPY scripts/ /data
RUN chmod 500 /data/entry.sh

HEALTHCHECK CMD ping -qc 3 193.138.218.74

ENTRYPOINT ["/data/entry.sh"]

