FROM golang:1.13.4-alpine
WORKDIR /go/src/rawkv_rw
ENV GO111MODULE on
COPY raw_rw.go raw_rw.go
RUN go mod init rawkv_rw && go get -d github.com/pingcap/tidb@master && go get -d ./...
RUN go install -v ./...

CMD ["go", "run", "raw_rw.go"]