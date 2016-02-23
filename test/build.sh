#!/bin/sh
xset=""
[ "$1" = -x    ] && shift && xset=-x && set -x
[ "$1" = clean ] && rm -rf dcc.yml tmp rep/client-ca.crt rep/client-crl && exit 0

f=authorize/ca/bin/ca.script
sh $xset $f create_tmp_ca  ||  exit $?
[ -f tmp/rootkey ] \
|| ssh-keygen -t rsa -C "temporary root key" -P "" -f tmp/rootkey -b 4096
rootkey=$(cat tmp/rootkey.pub)

sed -e "/RootKey=/  s|=.*|=$rootkey|" \
    -e "/SSH_KEY=/  s|=.*|=$rootkey|" \
        docker-compose.yml > dcc.yml

cp tmp/ca/intermediate/certs/ca-chain.cert.pem  rep/client-ca.crt
cp tmp/ca/intermediate/crl/intermediate.crl.pem rep/client-crl

docker-compose -f dcc.yml build

docker-compose -f dcc.yml up -d dregit authorize  ; sleep 5
if ! grep -iq "host  *dregit" $HOME/.ssh/config
   then
      (
      echo
      echo "Host          dregit"
      echo "HostName      localhost"
      echo "User          git"
      echo "Port          1140"
      echo "IdentityFile  $PWD/tmp/rootkey"
      echo "StrictHostKeyChecking no"
      ) >> $HOME/.ssh/config
   fi
if ! grep -iq "host  *authorize" $HOME/.ssh/config
   then
      (
      echo
      echo "Host          authorize"
      echo "HostName      localhost"
      echo "User          root"
      echo "Port          1122"
      echo "IdentityFile  $PWD/tmp/rootkey"
      echo "StrictHostKeyChecking no"
      ) >> $HOME/.ssh/config
   fi
if ! grep -iq 'host  *\*$' $HOME/.ssh/config
   then
      (
      echo
      echo "Host          *"
      echo "StrictHostKeyChecking no"
      ) >> $HOME/.ssh/config
   fi
##### if access is denied, please check admin-key in dregit-repo!!
if [ -d tmp/gitadm ]
   then
      ln -s ../../tmp tmp/gitadm/. 2>/dev/null
      (cd tmp/gitadm && git pull --rebase || exit 1)
   else
      git clone ssh://dregit/gitolite-admin tmp/gitadm
   fi
key=$(cat tmp/gitadm/keydir/automation.pub)
[ -z "$key" ] && echo "no admin key found -- exit with error" >&2 && exit 1
key='no-pty,no-port-forwarding,command="/etc/ca/bin/login"'" $key"
(cd tmp/ca && tar -cf - intermediate* | ssh authorize "echo '$key' >> /root/.ssh/authorized_keys; cd \$CaBase && tar -xf -")
