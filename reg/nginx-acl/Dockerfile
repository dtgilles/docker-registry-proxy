FROM nginx:1.9

RUN apt-get update; apt-get install vim-tiny; apt-get clean; rm -rf /var/lib/apt/list/*

EXPOSE 80

COPY htpasswd /etc/nginx/htpasswd
COPY config   /etc/nginx/conf.d/default.conf
