FROM dtgilles/sshgw

RUN  echo 'Acquire::http::proxy "http://cfproxy:8888/";' > /etc/apt/apt.conf \
	&& apt-get update \
	&& apt-get install -qy             ca-certificates nginx gettext-base \
        && apt-get install -qy             curl apache2-utils vim-tiny \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN        ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

# ENV  CA_PASSWORD_ROOT
# ENV  CA_PASSWORD_INTERMEDIATE
# ENV  CaBase                    /data/ca_private
# ENV  START_NGINX               yes

RUN  f=/usr/share/nginx/html/ok; echo "auth successful" > $f && chmod 0644 $f
COPY ca nginx                         /etc/
COPY nginx-entry.add                  /etc/default/ssh
