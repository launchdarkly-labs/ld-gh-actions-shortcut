FROM alpine

RUN apk add --no-cache bash jq curl

ARG OK_SH_VERSION=0.7.0

# Install ok.sh, a bash github client
RUN curl -fsSL https://github.com/whiteinge/ok.sh/archive/${OK_SH_VERSION}.tar.gz -o- | \
        tar -xzvf - --strip-components=1 -C /usr/bin/ ok.sh-${OK_SH_VERSION}/ok.sh

ADD entrypoint.sh /usr/bin

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
