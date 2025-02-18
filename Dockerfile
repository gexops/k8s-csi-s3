FROM golang:1.16-alpine as gobuild

WORKDIR /build
ADD go.mod go.sum /build/
ADD cmd /build/cmd
ADD pkg /build/pkg

RUN go get -d -v ./...
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o ./s3driver ./cmd/s3driver

FROM debian:buster-slim
LABEL maintainers="Tri Songz <ts@growthengineai.com>"
LABEL description="csi-s3 slim image"

# apk add temporarily broken:
#ERROR: unable to select packages:
#  so:libcrypto.so.3 (no such package):
#    required by: s3fs-fuse-1.91-r1[so:libcrypto.so.3]
# S3FS
RUN apt-get update && \
  apt-get install -y \
  libfuse2 gcc sqlite3 libsqlite3-dev \
  s3fs psmisc procps libcurl4 xfsprogs curl unzip && \
  rm -rf /var/lib/apt/lists/*


ADD https://github.com/yandex-cloud/geesefs/releases/latest/download/geesefs-linux-amd64 /usr/bin/geesefs
RUN chmod 755 /usr/bin/geesefs

COPY --from=gobuild /build/s3driver /s3driver
ENTRYPOINT ["/s3driver"]
