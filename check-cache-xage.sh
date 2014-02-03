#!/bin/bash

#url file is exported by c&p from analytics: top-articles-by-wiki-and-namespace, lines in the format: "url pageviews"
# TODO add option to fetch urls from db
urlfile="$1"

cat $urlfile|while read url pageviews; do
#    echo "url: $url pageviews: $pageviews"
    echo -n "."
    xageseconds=`curl --compressed -s -I $url|perl -ne 'print $1 if s/X-Age:\s(\d+)/$1/'`
    if [ $xageseconds -gt 86400 ]; then
      echo "X-Age > 24h (X-Age=$xageseconds) for url: $url"
      echo "$url" >> stale-cache.log
      if [ $xageseconds -gt 604800 ]; then
        echo "     ******   X-Age > 7d (X-Age=$xageseconds) for url: $url    *****"
      fi
    fi
done

echo
echo "All urls checked"
