ARG BASEIMG
FROM ${BASEIMG}
COPY main.go /go/src/storer/main.go
RUN go install storer
ENTRYPOINT /go/bin/storer
EXPOSE 8080
LABEL description="Store text in a text file, with API read/write access to it"

