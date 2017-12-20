FROM golang
COPY main.go /go/src/getmac/main.go
RUN go install getmac
ENTRYPOINT /go/bin/getmac
EXPOSE 8080
LABEL description="Get node's MAC address"

