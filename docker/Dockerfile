# FakeSIP sidecar image — builds the binary from THIS repository's source.
# Build context must be the repository root:
#   docker build -f docker/Dockerfile -t fakesip-sidecar:1.0 .
#
# Stage 1 compiles src/ with the stock Makefile (dynamic linking).
# Stage 2 is a minimal runtime: nftables CLI + the three runtime .so deps.

FROM alpine:3.19 AS build
# Use a CN mirror for apk; drop the sed if you build outside CN.
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
    && apk add --no-cache \
        gcc make musl-dev linux-headers \
        libmnl-dev libnfnetlink-dev libnetfilter_queue-dev
WORKDIR /build
COPY Makefile Makefile
COPY include/ include/
COPY src/ src/
RUN make -j4

FROM alpine:3.19
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
    && apk add --no-cache nftables libmnl libnfnetlink libnetfilter_queue
COPY --from=build /build/build/fakesip /usr/local/bin/fakesip
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod 755 /usr/local/bin/fakesip /entrypoint.sh \
    && mkdir -p /var/log
ENTRYPOINT ["/entrypoint.sh"]
