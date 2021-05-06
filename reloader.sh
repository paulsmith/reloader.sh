#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
	echo "$(basename "$0") [buildandruncmd | buildcmd runcmd]" 1>&2
	exit 1
fi

buildcmd=
runcmd="$1"
if [ $# -ge 2 ]; then
	# the first arg is actually a build step
	buildcmd="$runcmd"
	runcmd="$2"
fi
if [ $# -ge 3 ]; then
	echo "WARNING: extra unprocessed arguments passed in: $*" 1>&2
fi
[ -n "$buildcmd" ] && $buildcmd
$runcmd &
serverpid=$!

shutdownall() {
	local pid="$1"
	for cpid in $(ps -o pid= --ppid "$pid"); do
		kill "$cpid"
	done
	kill "$pid"
	wait
}

trap 'shutdownall $serverpid 2>/dev/null' SIGTERM EXIT
trap 'exit' SIGINT

fswatch -1 -r -l 0.25 --event Updated --event Created --event Removed . >/dev/null
echo -e "\e[33mReloading\e[0m"
shutdownall "$serverpid"
exec "$0" "$@"
