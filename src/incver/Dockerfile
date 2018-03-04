ARG BASEIMG
FROM golang
ARG ARCH
ARG ARM=1
COPY main.go /go/src/incver/main.go
RUN go get github.com/gorilla/websocket
WORKDIR /go/src/incver/
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} GOARM=${ARM} go build -a -installsuffix cgo -o /go/bin/incver .
FROM ${BASEIMG}
ARG VERSION
COPY --from=0 /go/bin/incver /go/bin/incver
ENV INCVER_VERSION=${VERSION}
COPY Dockerfile /var/www/
COPY *.sh /var/www/
COPY main.go /var/www/
WORKDIR /var/www/
ENTRYPOINT /go/bin/incver
EXPOSE 8080
LABEL description="This service can output it's own version and update the incver-deployment in namespace kube-alive to an image of a newer version."

