#!/bin/sh

server="localhost:9393"

url="www.foobar.com"
uuid="REPLACEME"

echo; echo " -- Logging a hit --"
curl -X PUT -d lol "http://$server/count.json?url=$url&uuid=$uuid"; echo

echo; echo " -- Get all visitors --"
curl "http://$server/site.json?url=$url"; echo

echo; exit 0
