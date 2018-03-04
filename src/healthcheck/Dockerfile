ARG BASEIMG
FROM golang
ARG ARCH
ARG ARM=1
COPY main.go /go/src/healthcheck/main.go
WORKDIR /go/src/healthcheck/
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} GOARM=${ARM} go build -a -installsuffix  cgo -o /go/bin/healthcheck .
FROM ${BASEIMG}
COPY --from=0 /go/bin/healthcheck /go/bin/healthcheck
ENTRYPOINT /go/bin/healthcheck
EXPOSE 8080
LABEL description="Experiment with unhealthy and crashing Pods"

