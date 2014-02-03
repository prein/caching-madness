#!/bin/bash

#url file is exported by c&p from analytics: top-articles-by-wiki-and-namespace, lines in the format: "url pageviews"
# TODO add option to fetch urls from db
urlfile="$1"

cat $urlfile|while read url pageviews; do
    echo -n "."
#    echo -n "  purging $url  "
#TODO: add error handling smarter than grep -v ok
    curl --compressed -s -X PURGE $url | grep -v ok
    sleep 0.1
done

echo
echo "All urls purged"
