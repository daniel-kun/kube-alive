ARG BASEIMG
FROM ${BASEIMG}
ARG VERSION
ENV INCVER_VERSION=${VERSION}
COPY main.go /go/src/incver/main.go
WORKDIR /var/www/
COPY static/index.html /var/www/static/index.html
COPY Dockerfile /var/www/
COPY main.go /var/www/
COPY build.sh /var/www/
RUN go get github.com/gorilla/websocket
RUN go install incver
ENTRYPOINT /go/bin/incver
EXPOSE 8080
LABEL description="Provide a way to get this service's version, build a new container with an incremented version, and track progress of the build"

