#!/bin/bash
access=GMGR882QK9J3346TICDX
secret=edd7NaBJWhPsVKue3eH89K337aQ6UNdBF83PZDNu
query=$1
query3="&uid="
query2=admin/user
date=$(date -R)
header="GET\n\n\n${date}\n/${query2}"
sig=$(echo -en ${header} | openssl sha1 -hmac ${secret} -binary | base64)
curl -v -H "Date: ${date}" -H "Authorization: AWS ${access}:${sig}" -L -X GET "http://127.0.0.1:8888/${query2}?format=json${query3}${query}" -H "Host: 127.0.0.1"
echo