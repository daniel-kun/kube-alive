FROM golang
COPY main.go /go/src/healthcheck/main.go
RUN go install healthcheck
ENTRYPOINT /go/bin/healthcheck
EXPOSE 8080
LABEL description="Experiment with unhealthy and crashing Pods"

