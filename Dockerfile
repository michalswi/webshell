ARG GOLANG_VERSION
ARG ALPINE_VERSION

# build
FROM golang:${GOLANG_VERSION}-alpine${ALPINE_VERSION} AS builder

RUN apk --no-cache add make git; \
    adduser -D -h /tmp/dummy dummy

USER dummy

WORKDIR /tmp/dummy

COPY --chown=dummy Makefile Makefile
COPY --chown=dummy go.mod go.mod
COPY --chown=dummy go.sum go.sum

RUN go mod download

ARG VERSION
ARG APPNAME

COPY --chown=dummy go-webshell.go main.go

RUN make go-build

# execute
FROM alpine:${ALPINE_VERSION}

ARG VERSION
ARG APPNAME

ENV SERVICE_ADDR "8080"

COPY --from=builder /tmp/dummy/${APPNAME}-${VERSION} /usr/bin/${APPNAME}

CMD ["webshell"]