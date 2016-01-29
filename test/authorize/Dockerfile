FROM dtgilles/sshgw

RUN  echo 'Acquire::http::proxy "http://cfproxy:8888/";' > /etc/apt/apt.conf \
	&& apt-get update \
	&& apt-get install -y             ca-certificates nginx gettext-base \
        && apt-get install -y             curl apache2-utils vim-tiny \
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
COPY perm.* htpass* defau*     /etc/nginx/
COPY nginx-entry.add           /etc/default/ssh
