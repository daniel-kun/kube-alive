ARG BASEIMG
FROM ${BASEIMG}

COPY index.html /www/data/
COPY *.elm /kube-alive/src/
COPY elm-package.json /kube-alive/src/
RUN cd /kube-alive/src && elm-make --yes Main.elm --output=/www/data/output/main.js

COPY nginx.conf /etc/nginx/
COPY run_nginx_with_service_account.sh /kube-alive/

CMD /kube-alive/run_nginx_with_service_account.sh 

