FROM nginx:1.9

RUN apt-get update; apt-get install vim-tiny; apt-get clean; rm -rf /var/lib/apt/list/*

COPY dd /usr/share/nginx/html/dreg

EXPOSE 80
