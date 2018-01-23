ARG BASEIMG
FROM ${BASEIMG}
COPY main.go /go/src/cpuhog/main.go
RUN go install cpuhog
ENTRYPOINT /go/bin/cpuhog
EXPOSE 8080
LABEL description="Hog CPU for 2 seconds for every response"

