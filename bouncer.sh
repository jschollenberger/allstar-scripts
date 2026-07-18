#!/bin/bash

# bouncer.sh - Detect and disconnect AllStar nodes which have subtended nodes.
# Copyright (C) 2021-2026 Jason Schollenberger
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# nodes to ignore
# FIX: elements must be space-separated, not comma-separated. The old
# comma form produced a single concatenated element, and the substring
# match against it could wrongly ignore nodes like "209" or "084".
IGNORE_NODES=("1999" "53209" "51205" "526450" "526084" "TKD2QED")

# log output
LOG_FILE="/tmp/bouncer.log"
exec 3>&1 1>>${LOG_FILE} 2>&1

# sleep so asterisk can catch up when calling on a new connection
sleep 1

echo_date () {
	echo "[$(date '+%m/%d/%Y %H:%M:%S')] "$1""
}

# FIX: exact-element match instead of substring match against the
# flattened array, so "209" no longer matches inside "53209".
is_ignored () {
	local n
	for n in "${IGNORE_NODES[@]}"; do
		[[ "$n" == "$1" ]] && return 0
	done
	return 1
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
	echo_date "No remote node ID provided. Processing all connected nodes..." | tee /dev/fd/3

	# read link list into array
	readarray -s2 -t LINKSLIST < <( asterisk -rx "rpt linkslist $NODE1" )
	# delete footer
	unset LINKSLIST[-1]
else
	REMOTE_NODE=$2
	# FIX: read into an array (one element per line) instead of a scalar,
	# so multiple grep matches don't get mashed into one jumbled record.
	# Also anchor the match to the node field so "209" doesn't match "53209".
	readarray -t LINKSLIST < <( asterisk -rx "rpt linkslist $NODE1" | grep -E "^${REMOTE_NODE}[[:space:]]" )
fi

# populate array with links
LINKS=("${LINKSLIST[@]}")

if [[ ${#LINKS[@]} -eq 0 ]] ; then
	echo_date "No links connected."
else
	for i in "${!LINKS[@]}"
	do
		node=$(echo ${LINKS[$i]} | cut -d' ' -f1)
		numlinks=$(echo ${LINKS[$i]} | cut -d' ' -f2)
		links=$(echo ${LINKS[$i]} | cut -d' ' -f3)

		if is_ignored "$node"; then
			echo_date "[$node] Ignored. $numlinks subtended nodes." | tee /dev/fd/3
		else
			if [[ $numlinks -gt 0 ]] ; then
				echo_date "[$node] $numlinks subtended nodes detected: $links. Disconnecting..." | tee /dev/fd/3
				# Disconnect offending node
				# /usr/sbin/asterisk -rx "rpt cmd $NODE1 ilink 11 $node"
			else
				echo_date "[$node] No subtended nodes detected." | tee /dev/fd/3
			fi
		fi
	done
fi
