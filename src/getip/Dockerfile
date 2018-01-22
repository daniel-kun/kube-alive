ARG ARCH
FROM ${ARCH}/golang:stretch
COPY main.go /go/src/getip/main.go
RUN go install getip
ENTRYPOINT /go/bin/getip
EXPOSE 8080
LABEL description="Get node's IP address"

