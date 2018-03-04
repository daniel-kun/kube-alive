ARG BASEIMG
FROM golang
ARG ARCH
ARG ARM=1
COPY main.go /go/src/cpuhog/main.go
WORKDIR /go/src/cpuhog/
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} GOARM=${ARM} go build -a -installsuffix cgo -o /go/bin/cpuhog .
FROM ${BASEIMG}
COPY --from=0 /go/bin/cpuhog /go/bin/cpuhog
ENTRYPOINT /go/bin/cpuhog
EXPOSE 8080
LABEL description="Hog CPU for 2 seconds for every response"

