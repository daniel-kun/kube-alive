sed "s/%%SERVICE_ACCOUNT_TOKEN%%/`cat /var/run/secrets/kubernetes.io/serviceaccount/token`/" -i /etc/nginx/nginx.conf && nginx -g "daemon off;"
