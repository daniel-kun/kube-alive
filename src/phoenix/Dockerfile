ARG BASEIMG
FROM ${BASEIMG}
COPY main.go /go/src/phoenix/main.go
RUN go install phoenix
ENTRYPOINT /go/bin/phoenix
EXPOSE 8080
LABEL description="Store text in a text file, with API read/write access to it. Rise from the ashes without losing the data."

