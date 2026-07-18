#!/bin/bash

# collect-stats.sh - Collect rpt stats from an AllStar node and append as CSV.
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

# Node can now be passed as $1; falls back to allstar.env, then the old default.
NODE="${1:-}"
if [ -z "$NODE" ] && [ -f /usr/local/etc/allstar.env ]; then
	source /usr/local/etc/allstar.env
	NODE="$NODE1"
fi
NODE="${NODE:-53209}"

STATS_DIR="/root/stats"
STATS_FILE="$STATS_DIR/stats"

# Make sure the output directory exists (silent cron failure otherwise).
mkdir -p "$STATS_DIR" || { echo "ERROR: cannot create $STATS_DIR" >&2; exit 1; }

STATS=$(asterisk -rx "rpt stats $NODE" | grep today | sed 's/.*\: //g' | paste -sd,)

# Don't write a useless "date-only" row if asterisk was down or returned nothing.
if [ -z "$STATS" ]; then
	echo "ERROR: no stats returned for node $NODE (is Asterisk running?)" >&2
	exit 1
fi

echo "$(date +"%D"),$STATS" >> "$STATS_FILE"
