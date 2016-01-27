FROM nginx:1.9

RUN apt-get update; apt-get install vim-tiny; apt-get clean; rm -rf /var/lib/apt/list/*

EXPOSE 80

RUN  echo "auth successful" > /usr/share/nginx/html/empty && chmod 0644 /usr/share/nginx/html/empty
COPY htpasswd /etc/nginx/htpasswd
COPY config   /etc/nginx/conf.d/default.conf
