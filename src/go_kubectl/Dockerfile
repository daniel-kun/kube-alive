ARG BASEIMG
FROM ${BASEIMG}
ARG ARCH
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/${ARCH}/kubectl && chmod +x kubectl && mv kubectl /usr/local/bin

