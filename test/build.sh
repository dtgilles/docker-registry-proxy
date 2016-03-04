#!/bin/sh
##### you could call this command like this:
#####  (  cd ~/git \
#         && tar -cf - docker-registry-proxy \
#         |  ssh boot2docker tar -xf - \
#         && echo 'cdocker-registry-proxy/test && sh build.sh -x ' \
#         |  ssh boot2docker
#      ) 2>&1 | more
xset=""
data_dir="${data_dir:-/tmp/docker_persist}"
CaPwdIm="${CaPwdIm:-im.o8wre7326erddsudfwz}"
[ "$1" = -x    ] && shift && xset=" -x" && set -x
[ "$1" = clean ] && rm -rf dcc.yml tmp rep/client-ca.crt rep/client-crl rep/secret && exit 0


##### if persistent data dir does not exist then new ssh host keys would be
##### genereated and known_hosts file is invalid ==> delete it to prevent error messages
[ -d "$data_dir" ] || rm $HOME/.ssh/known_hosts

mkdir -p "$data_dir/dregit/sshd_keys" \
         "$data_dir/authorize/sshd_keys" || exit 1

if ! grep -iq "host  *test_dregit" $HOME/.ssh/config
   then
      (
      echo
      echo "Host          test_dregit"
      echo "HostName      localhost"
      echo "User          git"
      echo "Port          1140"
      echo "IdentityFile  $PWD/tmp/gitadm/keydir/mr.nobody"
      echo "StrictHostKeyChecking no"
      ) >> $HOME/.ssh/config
   fi
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


prep_ca()
   {
      f=authorize/ca/bin/ca.script
      sh $xset $f create_tmp_ca  ||  exit $?
      [ -f tmp/rootkey ] \
      || ssh-keygen -t rsa -C "temporary root key" -P "" -f tmp/rootkey -b 4096
      rootkey=$(cat tmp/rootkey.pub)
      sed -e "/RootKey=/  s|=.*|=$rootkey|" \
          -e "/SSH_KEY=/  s|=.*|=$rootkey|" \
          -e "s|%%data_dir%%|$data_dir|"     \
          -e "s|%%CaPwdIm%%|$CaPwdIm|"     \
              docker-compose.yml > dcc.yml
      cp tmp/ca/intermediate/certs/ca-chain.cert.pem  rep/client-ca.crt
      cp tmp/ca/intermediate/private/.secret          rep/secret
      cp tmp/ca/intermediate/crl/intermediate.crl.pem rep/client-crl
   }

dcc()
   {
      docker-compose -f dcc.yml build
      docker-compose -f dcc.yml kill dregit authorize
      docker-compose -f dcc.yml rm -f dregit authorize
      docker-compose -f dcc.yml up -d dregit authorize || exit 2
      sleep 8
   }

##### get automation key
get_akey()
   {
      ##### if access is denied, please check admin-key in dregit-repo!!
      if [ -d tmp/gitadm ]
         then
            (cd tmp/gitadm && git pull --rebase)
         else
            git clone ssh://dregit/gitolite-admin tmp/gitadm || exit 1
            (   cd tmp/gitadm                                || exit 1
                git config user.name   ci-admin              || exit 1
                git config user.email  ci-admin@nowhere.org  || exit 1
            )                                                || exit $?
         fi
   }

dist_akey()
   {
      key=$(cat tmp/gitadm/keydir/automation.pub)
      [ -z "$key" ] && echo "no admin key found -- exit with error" >&2 && exit 1
      key='no-pty,no-port-forwarding,command="/etc/ca/bin/login'"$xset\" $key"
      #echo  "DEBUG: echo '$key' >> /root/.ssh/authorized_keys; cd \$CaBase && tar -xf -"
      (cd tmp/ca && tar -cf - intermediate* | ssh authorize "echo '$key' >> /root/.ssh/authorized_keys; cd \"\$CaBase\" && tar -xf - && rm intermediate/openssl.conf") || exit 1
   }

dcc_up()
   {
      [ $(docker-compose -f dcc.yml ps | egrep -ic "authorize.* up |dregit.* up ") = 2 ] \
      && echo container sind oben \
      || dcc
   }

my_()
   {
      dcc_up
      ssh dregit My $xset passwd GanzGehe1m || exit 1
      ssh dregit My $xset pr                || exit 1
   }


[ $# = 0 ] && set -- prep_ca dcc get_akey dist_akey my_
while [ $# -gt 0 ]
   do
      $1
      shift
   done



#### client certificates currently don't work
exit 0
#### client certificates currently don't work
##### use currently distributed automation key to create and revoke a certifikate for a testuser:
if [ ! -f tmp/gitadm/keydir/mr.nobody.pub ]
   then
      (
         cd tmp/gitadm/keydir                                                     || exit 1
         rm -f mr.nobody
         ssh-keygen -t rsa -C "temporary test key" -P "" -f mr.nobody -b 2048     || exit 1
         git add mr.nobody.pub                                                    || exit 1
         git commit -am "new user 'mr.nobody' for test purposes -- remove that user in production environments"
         git push origin                                                          || exit 1
      ) || exit $?
   fi

ssh test_dregit My name
ssh test_dregit My cert create MyP@ssw0rd1sSecret
ssh test_dregit My cert revoke
