FROM nginx

COPY nginx.conf /etc/nginx/
COPY index.html /www/data/
COPY output/main.js /www/data/output/main.js
COPY run_nginx_with_service_account.sh /kube-alive/

CMD /kube-alive/run_nginx_with_service_account.sh 

