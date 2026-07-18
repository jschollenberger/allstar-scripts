#!/bin/bash

# disconnect-outbound-links.sh - Disconnect all outbound links from an
# AllStar node.
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
	# FIX: was "$NODE1=$1", which expands empty $NODE1 first and tries to
	# run "=<arg>" as a command -- NODE1 was never set from the argument.
	NODE1=$1
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
