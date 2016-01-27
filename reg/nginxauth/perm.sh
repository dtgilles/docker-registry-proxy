#!/bin/bash

input=${1:-perm.info}
output=${2:-${input%.info}.conf}
#output=perm.conf

if [ ! -f "$input" ]
   then
      echo "Error: permission info input file not found == exit" >&2
      exit 1
   fi

(
   first=yes
   while read http_method user
      do
         case "$http_method"
            in
               ""|\#*)	: ;;
               location|=====)                                ##### if this is a location then
                     [ "$first" = yes ] && first=no || echo "    }"
                     printf '    location %s {\n' "$user"     ##### $user is the location value
                  ;;
               *)
                     http_method="${http_method:-.*}"
                     user="${user:-.*}"
                     printf '       if ($acl ~ %-40s) { rewrite /.* /empty  break; }\n' \
                         "\"^/(${http_method})/(${user})/$\""
                  ;;
            esac
      done
   [ "$first" = yes ] && first=no || echo "    }"
)  \
<  "$input" \
>  "$output"


exit 0
