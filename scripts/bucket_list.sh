#!/bin/bash
access=GMGR882QK9J3346TICDX
secret=edd7NaBJWhPsVKue3eH89K337aQ6UNdBF83PZDNu
query2=admin/bucket
date=$(date -R) # RFC-822 date
header="GET\n\n\n${date}\n/${query2}"
sig=$(echo -en ${header} | openssl sha1 -hmac ${secret} -binary | base64) # AWS sig V2
curl -v -H "Date: ${date}" -H "Authorization: AWS ${access}:${sig}" -L -X GET "http://127.0.0.1:8888/${query2}?format=json&stats=true" -H "Host: 127.0.0.1" | jq .
