ARG BASEIMG
FROM golang
ARG ARCH
ARG ARM=1
COPY main.go /go/src/getip/main.go
WORKDIR /go/src/getip/
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} GOARM=${ARM} go build -a -installsuffix cgo -o /go/bin/getip .
FROM ${BASEIMG}
COPY --from=0 /go/bin/getip /go/bin/getip
WORKDIR /go/bin/
ENTRYPOINT ["/go/bin/getip"]
EXPOSE 8080
LABEL description="Get node's IP address"

