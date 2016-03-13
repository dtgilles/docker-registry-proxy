## abstract
This is a small infratructure to run a docker registry behind a reverse
proxy (nginx) that does ssl termination as well as authentication based on
ssl client certificates, for request authorization it asks "authorization".

!!! THIS IS ALPHA !!!

## build and install
To do a fist test installation go to "test/" and call "build.sh" without any
parameters. This will:
* create a private certificate authority (root + intermediary) and test
  this creating + revoking a client certificate
* create a private ssh key which will be granted root privileges to dregit-
  and authorize ssh daemons
* create a docker compose yml with the correct credentials 
* call docker-compose build
* recreate relevant containers and sleep a while to give them a chance to start
* read automation key from dregit's admin repository
* distribute this key as well as im-CA directory to authorize container
  automation key is restricted to special login shell with restricted rights
* define and checkout/clone a regular repo "sshgw" and create a sync-key to read that
* last but not least test prepared infrastructure calling dregit/My:
  * create and download a client certificate
  * revoke that cert
  * set an http password
  * distribute permissions to authorize container (and test it) and to sshgw repo

## architecture

Following containers are part of this example infrastructure (referenced in docker-compose.yml):
* the official open source docker registry
* an nginx reverse proxy
  * terminates ssl and hence
  * authenticates users (by their certificates)
  * and asks "authorize" to authorize the (registry) requests
* authorize is
  * a simple nginx answering with http-200, 401 and 403 to grant or deny access
    (simple ssh based api to change authorization config)
  * contains a ca (certificate authority) and offers
    * an (ssh based) api to create/revoke client certificates
    * the possibility to download client certificates for a short time period
    * changed revokation lists (crl) for http download
* dregit is a ssh+gitolite container
  * if a git repository will be created, it is assumed that the registry path
    will be of the same name, so if access is granted to a person (e.g. read)
    to the git repositry this person will have the same grants (read) to
    corresponding registry path
  * you can control namespaces, groups and roles using gitolite features
    like wild repos, roles and groups
  * Command My is a user frontend to
    * create / revoke ssl client certificates
    * distribute permission information to "authorize" container and -- if 
      configured -- a repo usable for ssh-gateways, see dtgilles/sshgw for 
      more details
    * if password authentication is activated in "authorize" you may change your password here as well


## Links
*  ssl client cert:  http://nategood.com/client-side-certificate-authentication-in-ngi
*  ca aufsetzen und nutzen: https://jamielinux.com/docs/openssl-certificate-authority/
