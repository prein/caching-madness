#!/bin/bash

#it is good idea to have it sorted by page popularity (pageviews)

OPTIND=1         # Reset in case getopts has been used previously in the shell.
url_file=""
proxies_file=""
log_file="cache-check.log"
max_age=86400
verbose=0
dry_run=0
usage="usage: $(basename "$0") [OPTIONS]
    -f FILE_WITH_URLS                 url file is one url per line in the format: \"url .*\" (everything after url is ignored)
    -m max_allowed_age (s)            report and purge pages cached for more then this long, default is 86400 (24h)
    [-p FILE_WITH_PROXIES_LIST]       (not yet supported) verify across list of proxy servers, one server per line, in the format: 1.2.3.4:80
    [-l LOG_FILE]                     pring log to this file, default: cache-check.log
    [-v]                              verbose
    [-n]                              dry-run: don't purge, only report
" 

[[ ! $1 ]] && { echo "$usage" >&2; exit 1; }

function log () {
    local logline=$1
    local logalways=$2
    if [[ $verbose -eq 1 ]]; then
        echo "$logline"
        echo "$logline" >> $log_file
    elif [[ $logalways -eq 1 ]]; then
        echo "$logline" >> $log_file
    fi
}

while getopts "hvm:f:p:l:n" opt; do
    case "$opt" in
    h)
        echo "$usage"
        exit 0
        ;;
    v)  verbose=1
        ;;
    n)  dry_run=1
        ;;
    f)  url_file=$OPTARG
        ;;
    p)  proxies_file=$OPTARG
        ;;
    m)  max_age=$OPTARG
        ;;
    l)  log_file=$OPTARG
        ;;
    \?) echo "$usage" >&2;
        exit 1;
        ;;
    esac
done

shift $(expr ${OPTIND} - 1)

[[ ! -f $url_file ]] && { echo "$usage" >&2; exit 1; }

#TODO make pv show progress bar correctly, mutted with -q untill this is done
pv -q -l -s $(wc -l $url_file) $url_file | while read -r url _; do
    log "checking url: $url"
    echo -n "."
    read etag servedby xageseconds <<<$(curl --compressed -s -I $url|perl -lne 'print $1 if /(?:X-Age|X-Served-By|ETag):.*\s(.+)$/')
    xageseconds=${xageseconds//[^[:digit:]]}
    if [ $xageseconds -gt $max_age ]; then
      log "X-Age: $xageseconds url: $url served_by: $servedby ETag: $etag" 1
      if [[ $dry_run -eq 0 ]]; then
        log "purging $url"
        log `curl --compressed -s -X PURGE $url | grep -v ok 2>&1` 1 
        sleep 0.5
      fi
    fi
done 

echo
echo "All urls checked"
