#!/bin/sh

server="localhost:9393"

url="foobar.com"
uuid="REPLACEME"

###

echo; echo " -- Joining site: $url"
curl -X PUT -d lol "http://$server/count.json?url=$url&uuid=$uuid"; echo

echo; echo " -- Joining site: www.$url"
curl -X PUT -d lol "http://$server/count.json?url=www.$url&uuid=$uuid"; echo

echo; echo " -- Joining site: http://$url"
curl -X PUT -d lol "http://$server/count.json?url=http://$url&uuid=$uuid"; echo

echo; echo " -- Joining site: http://www.$url"
curl -X PUT -d lol "http://$server/count.json?url=http://www.$url&uuid=$uuid"; echo

###

echo; echo " -- Get site stats --"
curl "http://$server/site.json?url=$url"; echo




echo; exit 0
