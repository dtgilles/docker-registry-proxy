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

if [ ! -f $DataDir/certs/server.cert ]
   then
      mkdir -p $DataDir/certs
      pwd=$(genpwd -nsB 20) || pwd=lai8orefe8kdhf
      echo "$pwd" >> $DataDir/certs/secrets
      openssl genrsa   -des3           -out    $DataDir/certs/server.key -passout "pass:$pwd" 4096
      openssl req -new -x509 -days 375 -key    $DataDir/certs/server.key -passin  "pass:$pwd" \
                       -sha256         -out    $DataDir/certs/server.cert \
                                       -subj   "/C=DE/ST=Hessen/L=Darmstadt/O=Security GmbH/CN=$ServerName"
      openssl verify                   -CAfile $DataDir/certs/server.cert \
                                               $DataDir/certs/server.cert 
   fi
if [     -f /etc/nginx/client-ca.crt ]&&[ ! -f $DataDir/certs/client-ca.crt ]
   then
      cp -p /etc/nginx/client-ca.crt           $DataDir/certs/client-ca.crt
   fi
