ARG BASEIMG
FROM ${BASEIMG}
ARG VERSION
ARG KUBEALIVE_DOCKER_REPO
ENV INCVER_VERSION=${VERSION}
ENV KUBEALIVE_DOCKER_REPO=${KUBEALIVE_DOCKER_REPO}
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
LABEL description="Provide a way to get this service's version, build a new container with an incremented version, and track progress of the build"

