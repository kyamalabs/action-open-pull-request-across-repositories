FROM alpine:latest AS builder

RUN apk --no-cache add git go make rsync jq && \
    git clone https://github.com/cli/cli.git gh-cli && \
    cd gh-cli && \
    make && \
    mv ./bin/gh /usr/local/bin/

FROM alpine:latest

WORKDIR /github/workspace

ADD entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

COPY --from=builder /usr/local/bin/gh /usr/local/bin/
