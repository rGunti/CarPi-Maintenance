#!/bin/bash
MAINT_START_FILE="/boot/start_maint"

SCRIPT_LOCATION="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -f $MAINT_START_FILE ]; then
	echo " STARTING MAINTENANCE MODE ... "
	sleep 1

	rm "$MAINT_START_FILE"
	cd "$SCRIPT_LOCATION"
	./maint-menu.sh
fi
