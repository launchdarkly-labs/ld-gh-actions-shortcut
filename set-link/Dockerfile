FROM alpine

RUN apk add --no-cache bash jq curl wget

ARG OK_SH_VERSION=0.7.0

# Install ok.sh, a bash github client
RUN cd /tmp && \
    wget https://github.com/whiteinge/ok.sh/archive/${OK_SH_VERSION}.tar.gz -O ok.tar.gz && \
    tar xvf ok.tar.gz && \
    cp ok.sh-${OK_SH_VERSION}/ok.sh /usr/bin/ && \
    chmod +x /usr/bin/ok.sh

ADD entrypoint.sh /usr/bin

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
