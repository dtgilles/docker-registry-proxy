#!/bin/bash

###############################################################################
# Name:         entry.sh
# Description:  Used as ENTRYPOINT for this docker container
#               currently it is only needed to put ENV variables to nginx config
###############################################################################

PATH=$PATH:/usr/sbin

[ "$1" = nginx ] || exec "$@"

##### $1 == nginx -- go forward
[ -r /etc/default/nginx ] &&  . /etc/default/nginx
sed   -e "s;%%DataDir%%;$DataDir;g" \
      -e "s;%%ServerName%%;$ServerName;g" \
<         /etc/nginx/conf.d/default.conf.template \
>         /etc/nginx/conf.d/default.conf
chmod 644 /etc/nginx/conf.d/default.conf

exec "$@"
