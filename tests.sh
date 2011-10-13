#!/bin/sh

server="localhost:9393"

url="foobar.com"
uuid="REPLACEME"

###

echo; echo " -- Joining site: $url"
curl "http://$server/join_protest.json?url=$url&uuid=$uuid"; echo

echo; echo " -- Joining site: www.$url"
curl "http://$server/join_protest.json?url=www.$url&uuid=$uuid"; echo

echo; echo " -- Joining site: http://$url with diff useragent"
curl -A foobar "http://$server/join_protest.json?url=http://$url&uuid=$uuid"; echo

echo; echo " -- Joining site: http://www.$url with diff useragent"
curl -A foobar2 "http://$server/join_protest.json?url=http://www.$url&uuid=$uuid"; echo

###

echo; echo " -- Get site stats"
curl "http://$server/stats.json?url=$url"; echo

echo; echo " -- Site stats protestor count should == 3"
curl "http://$server/stats.json?url=$url" | python -mjson.tool | grep protestor_count



echo; exit 0
