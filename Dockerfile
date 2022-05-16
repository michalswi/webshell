ARG GOLANG_VERSION
ARG ALPINE_VERSION

# build
FROM golang:${GOLANG_VERSION}-alpine${ALPINE_VERSION} AS builder

ARG VERSION
ARG APPNAME

RUN apk --no-cache add make git; \
    adduser -D -h /dummy dummy

USER dummy
WORKDIR /dummy

COPY --chown=dummy Makefile Makefile
COPY --chown=dummy go.mod go.mod
COPY --chown=dummy go.sum go.sum
COPY --chown=dummy go-webshell.go main.go

RUN go mod download
RUN make go-build

# execute
FROM alpine:${ALPINE_VERSION}

ARG VERSION
ARG APPNAME

ENV SERVICE_ADDR "8080"

RUN adduser -D -h /dummy dummy
USER dummy
WORKDIR /dummy

COPY --from=builder /dummy/${APPNAME}-${VERSION} ./${APPNAME}

CMD ["./webshell"]
