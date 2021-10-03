#!/bin/bash

# Check if we're already running

if pidof -o %PPID -x "disconnect-outbound-links.sh">/dev/null; then
    echo "Process already running"
    exit 1
fi

if [ -z "$1" ]; then
    if [ -f /usr/local/etc/allstar.env ] ; then
        source /usr/local/etc/allstar.env
    else
        echo "No local node ID provided and missing Allstar environment file (/usr/local/etc/allstar.env). Exiting..."
        exit 1
    fi
else
    $NODE1=$1
fi

OUTBOUNDLINKS=`asterisk -rx "rpt lstats $NODE1" | grep "OUT" | awk {'print $1'}`
if [[ -z "$OUTBOUNDLINKS" ]] ; then
    echo "No outbound links connected."
else
    for i in $OUTBOUNDLINKS
    do
        echo "Disconnecting $i from $NODE1"
        /usr/sbin/asterisk -rx "rpt cmd $NODE1 ilink 11 $i"
    done
fi
