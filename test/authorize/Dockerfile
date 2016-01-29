FROM dtgilles/sshgw

# following lines are taken from nginx:1.9/Dockerfile
ENV NGINX_VERSION 1.9.10-1~jessie
#
RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
	&& echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install -y ca-certificates nginx=${NGINX_VERSION} gettext-base   curl apache2-utils vim-tiny \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

ENV  START_NGINX  yes
ENV  CA_Dir       /data/ca_private
ENV  RP_Dir       /data/reverse_proxy
ENV  RP_Name      example.telekomcloud.de

RUN  f=/usr/share/nginx/html/authorized.txt; echo "auth successful" > $f && chmod 0644 $f
COPY htpasswd     /etc/nginx/htpasswd.xmpl
COPY perms.*      /etc/nginx/.
COPY config   /etc/nginx/conf.d/default.conf.template
