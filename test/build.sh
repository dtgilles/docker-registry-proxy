#!/bin/sh
xset=""
[ "$1" = -x    ] && shift && xset=-x && set -x
[ "$1" = clean ] && rm -rf dcc.yml tmp rep/client-ca.crt rep/client-crl && exit 0

f=authorize/ca/bin/ca.script
sh $xset $f create_tmp_ca  ||  exit $?
ssh-keygen -t rsa -C "temporary root key" -P "" -f tmp/rootkey -b 4096
rootkey=$(cat tmp/rootkey.pub)

sed -e "/RootKey=/  s|=.*|=$rootkey|" \
       "/SSH_KEY=/  s|=.*|=$rootkey|" \
        docker-compose.yml > dcc.yml

cp tmp/ca/intermediate/certs/ca-chain.cert.pem  rep/client-ca.crt
cp tmp/ca/intermediate/crl/intermediate.crl.pem rep/client-crl

docker-compose -f dcc.yml build
