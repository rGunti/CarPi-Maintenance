#!/bin/bash
# heavily inspired by http://fitnr.com/showing-file-download-progress-using-wget.html
URL=$1

wget --limit-rate=50k "$URL" 2>&1 | \
 stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | \
 whiptail --gauge "Download Test" 7 52 0

#wget --progress=dot "$URL" 2>&1 |\
#grep "%" |\
#sed -u -e "s,\.,,g" | awk '{print $2}' | sed -u -e "s,\%,,g"  | whiptail --gauge "Download Test" 7 52 0
