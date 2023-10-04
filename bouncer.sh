#!/bin/bash

# Script to detect and disconnect nodes which have subtended nodes.

# nodes to ignore
IGNORE_NODES=("1999","53209","51205","526450","526084","TKD2QED")

# log output
LOG_FILE="/tmp/bouncer.log"
exec 3>&1 1>>${LOG_FILE} 2>&1

# sleep so asterisk can catch up when calling on a new connection
sleep 1

echo_date () {
    echo "[$(date '+%m/%d/%Y %H:%M:%S')] "$1""
}

if [ -z "$1" ]; then
    if [ -f /usr/local/etc/allstar.env ] ; then
        source /usr/local/etc/allstar.env
    else
        echo_date "No local node ID provided and missing Allstar environment file (/usr/local/etc/allstar.env). Exiting..."
        exit 1
    fi
else
    NODE1=$1
fi

if [ -z "$2" ]; then
    echo_date "No remote node ID provided. Processing all connected nodes..."  | tee /dev/fd/3

    # read link list into array
    readarray -s2 -t LINKSLIST < <( asterisk -rx "rpt linkslist $NODE1" )

    # delete footer
    unset LINKSLIST[-1]
else
    REMOTE_NODE=$2
    LINKSLIST=`asterisk -rx "rpt linkslist $NODE1" | grep $REMOTE_NODE`
fi

# populate array with links
LINKS=("${LINKSLIST[@]}")


if [[ -z "$LINKS" ]] ; then
    echo_date "No links connected."
else
    for i in "${!LINKS[@]}"
    do
        node=$(echo ${LINKS[$i]} | cut -d' ' -f1)
        numlinks=$(echo ${LINKS[$i]} | cut -d' ' -f2)
        links=$(echo ${LINKS[$i]} | cut -d' ' -f3)

        echo $node
        echo $numlinks
        echo $links


        if [[ " ${IGNORE_NODES[*]} " =~ "${node}" ]]; then
            echo_date "[$node] Ignored. $numlinks subtended nodes."  | tee /dev/fd/3
        else
            if [[ $numlinks -gt 0 ]] ; then
                echo_date "[$node] $numlinks subtended nodes detected: $links. Disconnecting..."  | tee /dev/fd/3
                # Disconnect offending node
                # /usr/sbin/asterisk -rx "rpt cmd $NODE1 ilink 11 $node"
            else
                echo_date "[$node] No subtended nodes detected."  | tee /dev/fd/3
            fi
        fi
    done

fi

