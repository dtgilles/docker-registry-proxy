#!/bin/bash

input=${1:-perm.info}
output=${2:-${input%.info}.conf}

##### helping functin to print acl config line
print_acl_line()
   {  ##### don't print anything if opening bracket is missed (first != no)
      [ "$first" = no ] || return 0
      printf '       if ($acl ~ %-40s) { rewrite /.* /ok  break; }\n' \
                    "\"^/(${http_method})/(${user})/$\""
   }

##### exit with error if input file does not exist
if [ ! -f "$input" ]
   then
      echo "Error: permission info input file not found == exit" >&2
      exit 1
   fi

##### parse input file and generate output (permission) file
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
               read)  http_method='GET|HEAD'                        ; print_acl_line;;
               write) http_method='GET|HEAD|PUT|POST|PATCH|DELETE'  ; print_acl_line;;
               debug) http_method='TRACE|OPTIONS'                   ; print_acl_line;;
               *)     print_acl_line;;
            esac
      done
   [ "$first" = yes ] && first=no || echo "    }"
)  \
<  "$input" \
>  "$output"


exit 0
