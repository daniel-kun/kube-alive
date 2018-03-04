ARG BASEIMG
FROM danielkun/elm-debian-x86_64
COPY src/* /kube-alive/src/
COPY elm-package.json /kube-alive/
RUN cd /kube-alive/ && elm-make --yes src/Main.elm --output=/www/data/output/main.js

FROM ${BASEIMG}
COPY index.html /www/data/
COPY --from=0 /www/data/output/main.js /www/data/output/main.js
COPY nginx.conf /etc/nginx/
COPY run_nginx_with_service_account.sh /kube-alive/

CMD /kube-alive/run_nginx_with_service_account.sh 

