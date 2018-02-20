ARG BASEIMG
FROM ${BASEIMG}
ARG VERSION
ENV INCVER_VERSION=${VERSION}
COPY main.go /go/src/incver/main.go
COPY static/index.html /var/www/static/index.html
COPY Dockerfile /var/www/
COPY *.sh /var/www/
COPY main.go /var/www/
RUN go get github.com/gorilla/websocket
RUN go install incver
WORKDIR /var/www/
ENTRYPOINT /go/bin/incver
EXPOSE 8080
LABEL description="This service can output it's own version and update the incver-deployment in namespace kube-alive to an image of a newer version."

