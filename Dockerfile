FROM golang:1.10-alpine as gethpkey
RUN apk add build-base git
RUN go get github.com/juztin/gethpkey


FROM ethereum/client-go:stable
COPY --from=gethpkey /go/bin/gethpkey /usr/local/bin/
COPY ./scripts/* /usr/local/bin/
WORKDIR /data
