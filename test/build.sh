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
verbose=""
[ "$1" = -v    ] && shift && verbose="-v"



##### if persistent data dir does not exist then new ssh host keys would be
##### genereated and known_hosts file is invalid ==> delete it to prevent error messages
[ -d "$data_dir" ] || rm -rf $HOME/.ssh/known_hosts tmp/sshgw

mkdir -p "$data_dir/dregit/sshd_keys" \
         "$data_dir/authorize/sshd_keys" 2>/dev/null

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
      docker-compose -f dcc.yml scale dregit=0 authorize=0
      docker-compose -f dcc.yml up -d dregit rep || exit 2
      sleep 15
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

prep_sshgw()
   {
      ##### create a wild repo sshgw,
      ##### grant permission to it,
      ##### create a special read user (not used yet)
      ##### and checkout/configure this wild repo
      (
         cd tmp/gitadm
         if ! grep -q sshgw conf/gitolite.conf
            then
               echo "repo sshgw"
               echo "    C       =   admin"
               echo "    RW+     =   admin"
               echo "    RW      =   automation"
               echo "    R       =   sshgw_sync"
            fi \
         >> conf/gitolite.conf
         if [ ! -f keydir/sshgw_sync.pub ]
            then
               rm -f keydir/sshgw_sync
               ssh-keygen -t rsa -C "temporary test key" -P "" -f keydir/sshgw_sync -b 2048
            fi
         git add keydir/sshgw_sync.pub conf/gitolite.conf                || exit 1
         git commit -am "added 'sshgw_sync' for test purposes"           || exit 1
         git push origin                                                 || exit 1
      )
      ##### create that initially in order to test auto creation of
      ##### ssh gateway user directory
      [ -d tmp/sshgw ]||git clone ssh://dregit/sshgw tmp/sshgw
      (   cd tmp/sshgw                                 || exit 1
          git config user.name   ci-admin              || exit 1
          git config user.email  ci-admin@nowhere.org  || exit 1
      )                                                || exit $?
   }

create_client_cert()
   {
      local output rc=0 uri
      output=$(ssh dregit My $xset $verbose cert create MyP@ssw0rd1sSecret) || rc=$?
      echo "$output"
      [ "$rc" -gt 0 ] && return 1
      echo "$output" \
      |  while IFS=":" read key value
         do
            [ "$key" = "download_uri" ] || continue
            uri="${value# }"
            https_proxy="" curl -k $uri > /dev/null \
            && echo "private certificate successfully downloaded" \
            || echo "download of private certificate failed"
            return 0
         done
      echo 'no download uri detected -- debug that!'
      return 0
   }

my_()
   {
      dcc_up
      [ -d tmp/sshgw ] || prep_sshgw
      echo $gleich  cert create
      create_client_cert                             || exit 1
      echo $gleich  cert revoke
      ssh dregit My $xset $verbose cert revoke       || exit 1
      echo $gleich  password
      ssh dregit My $xset $verbose passwd GanzGehe1m || exit 1
      echo $gleich  permission
      ssh dregit My $xset $verbose pr                || exit 1
   }

gleich="============================================"
printf "%s==============%s\n" $gleich $gleich
[ $# = 0 ] && set -- prep_ca dcc get_akey dist_akey prep_sshgw my_
while [ $# -gt 0 ]
   do
      sleep 1
      printf "%s %-12s %s\n" "$gleich" "$1" "$gleich"
      $1
      shift
   done
printf "%s==============%s\n" $gleich $gleich

exit 0
