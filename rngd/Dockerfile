# The build context is the root of the source tree:
#	docker build -f rngd/Dockerfile .
FROM alpine

RUN apk add --no-cache linux-headers zig

WORKDIR /source
COPY . .

# Static, so that the second stage needs nothing but the daemon.
RUN zig build -Drngd=true -Dlinkage=static -Dtools=false --prefix /build

FROM alpine

COPY --from=0 /build/sbin/jitterentropy-rngd /usr/bin

# -F: the daemon is the container's main process and must not detach.
ENTRYPOINT ["/usr/bin/jitterentropy-rngd"]
CMD ["-F", "-v"]
