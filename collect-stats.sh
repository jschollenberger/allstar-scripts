#!/bin/bash

# Collects rpt stats and outputs them as CSV to a file

OUT=`date +"%D"`
OUT="$OUT,`asterisk -rx 'rpt stats 53209' | grep today | sed 's/.*\: //g' | paste -sd,`"
echo $OUT >> /root/stats/stats