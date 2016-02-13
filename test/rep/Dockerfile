FROM nginx:1.9

# --no-install-recommends?
#RUN echo 'Acquire::http::proxy "http://cfproxy:8888/";' > /etc/apt/apt.conf
#RUN apt-get update; apt-get install -qy curl vim-tiny; apt-get clean; rm -rf /var/lib/apt/list/*

EXPOSE 443

ENV  DataDir      /data/reverse_proxy
ENV  ServerName   example.telekomcloud.de

COPY entry.sh /entry.sh
ENTRYPOINT ["/entry.sh"]
CMD        ["nginx","-g","daemon off;"]

#             nginx.conf includes conf.d/*.conf (not *template)
RUN  mkdir -p       /usr/share/nginx/html/ca
COPY config         /etc/nginx/conf.d/default.conf.template
COPY client-ca.crt  /etc/nginx/client-ca.crt
COPY client-crl     /usr/share/nginx/html/ca/intermediate.crl.pem
