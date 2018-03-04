ARG BASEIMG
FROM alpine
ARG ARCH
WORKDIR /
RUN apk update && apk add curl && curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/${ARCH}/kubectl && chmod +x kubectl
FROM ${BASEIMG}
COPY --from=0 /kubectl /usr/local/bin/kubectl
