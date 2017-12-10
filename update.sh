#!/bin/bash

VERSION=0.1
BACKTITLE="CarPi Updater Ver. $VERSION"

SCRIPT_LOCATION="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_LOCAL_CACHE=./repo
MASTER_REPO_ADDR="https://github.com/rGunti/carpi-repolist.git"

SCREEN_WIDTH=53
SCREEN_HEIGHT=20
DIALOG_HEIGHT=$(expr $SCREEN_HEIGHT - 2)

export NCURSES_NO_UTF8_ACS=1

function setGaugeStatus {
	echo XXX
	echo $2
	echo $1
	echo XXX
}

function downloadFile {
	URL=$1
	target=$2
	downloadMessage=$3
	wget -O "$target" "$URL" 2>&1 | \
		stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | \
		whiptail \
			--title "Downloading" \
			--backtitle "$BACKTITLE" \
			--gauge "$downloadMessage" \
			7 52 0
}

function respondToAutoScript {
	case $1 in
	0)
		NEWT_COLORS='
		  window=,green
		  border=black,green
		  textbox=black,green
		  title=black,green
		  button=white,black
		  actbutton=white,black
		' \
		whiptail \
			--title "Installation successfull" \
			--backtitle "$BACKTITLE" \
			--msgbox "$(cat "$SCRIPT_LOCATION/res/autoscript_success.msg")" \
			0 0
		;;
	*)
		error_msg=""
		if [ -f "$SCRIPT_LOCATION/res/autoscript_$1.msg" ]; then
			error_msg="$(cat "$SCRIPT_LOCATION/res/autoscript_$1.msg")"
		else
			error_msg="Failed with Code $1!"
		fi
		NEWT_COLORS='
		  window=,red
		  border=white,red
		  textbox=white,red
		  title=white,red
		  button=white,black
		  actbutton=white,black
		' \
		whiptail \
			--title "Error" \
			--backtitle "$BACKTITLE" \
			--msgbox "$error_msg" \
			0 0
		;;
	esac
}

function runBackgroundProcess {
	SCRIPT=$1
	OUTPUT=$2
	TITLE=$3
	PROCESSING_MSG=$4

	/bin/bash "$SCRIPT" 1>"$OUTPUT" &
	pid=$!
	spin='-\|/'
	i=0
	while kill -0 $pid 2>/dev/null
	do
		i=$(( (i+1) %4 ))
		status=$(tail -n4 "$OUTPUT")
		printf "\n$status\n"
		#printf "\nXXX\n0\n${spin:$i:1} $PROCESSING_MSG \nXXX\n"
		sleep 0.1
	done > >(whiptail \
		--title "$TITLE" \
		--backtitle "$BACKTITLE" \
		--gauge "Please wait ..." \
		7 $SCREEN_WIDTH 0)
	wait $pid
	respondToAutoScript $?
}

function unzipFile {
	unzipFile=$1
	
	while true; do
		setGaugeStatus "Unpacking files..." 0
		cd $REPO_LOCAL_CACHE
		unzip -o $unzipFile
		break
	done > >(whiptail \
		--title "Extracting ..." \
		--backtitle "$BACKTITLE" \
		--gauge "Extracting Files ..." \
		9 $SCREEN_WIDTH 0)
}

function runAutoScript {
	autoScriptPath=$1
	logPath=$2
	dialogTitle=$3
	
	if [ -f "$autoScriptPath" ]; then
		runBackgroundProcess \
			"$autoScriptPath" \
			"$logPath" \
			"$dialogTitle" \
			"This might make a second or two ..."
	else
		respondToAutoScript 404
	fi
}

# https://askubuntu.com/questions/776831/whiptail-change-background-color-dynamically-from-magenta
NEWT_COLORS='
  window=,yellow
  border=black,yellow
  textbox=black,yellow
  title=white,yellow
  button=black,white
  actbutton=black,white
' \
whiptail \
	--title "UPDATE WARNING!" \
	--backtitle "$BACKTITLE" \
	--msgbox "$(cat ./res/update_warn.msg)" \
	0 0

# Check Internet Connection
status=0
for ((i = 0; i < 100; i+=20)); do
	wget -q --spider http://github.com
	if [ $? -eq 0 ]; then
		status=1
		break
	else
		echo $i
		sleep 2
	fi
done > >(whiptail \
	--backtitle "$BACKTITLE" \
	--title "Test Internet Connection" \
	--gauge "Please wait while we're checking your internet connection..." \
	9 $SCREEN_WIDTH 0)

if [ $status -eq 1 ]; then
	NEWT_COLORS='
	  window=,green
	  border=black,green
	  textbox=black,green
	  title=black,green
	  button=white,black
	  actbutton=white,black
	' \
	whiptail \
		--title "Test Internet Connection" \
		--backtitle "$BACKTITLE" \
		--msgbox "$(cat ./res/update_net_test_success.msg)" \
		0 0
else	
	NEWT_COLORS='
	  window=,red
	  border=white,red
	  textbox=white,red
	  title=white,red
	  button=white,black
	  actbutton=white,black
	' \
	whiptail \
		--title "OFFLINE" \
		--backtitle "$BACKTITLE" \
		--msgbox "$(cat ./res/update_net_test_fail.msg)" \
		0 0
	exit 1
fi

cd $SCRIPT_LOCATION
if [ -f $REPO_LOCAL_CACHE ]; then
	rm -rf "$REPO_LOCAL_CACHE"
fi
mkdir -p "$REPO_LOCAL_CACHE"

# Show Menu
while true; do
	cd $SCRIPT_LOCATION
	
	update_menu=$(whiptail \
		--title "Update" \
		--backtitle "$BACKTITLE" \
		--menu  "Select a component to update:" \
		15 $SCREEN_WIDTH 7 \
		"DAEMONs"  "CarPi Daemons (Data providers)   " \
		"TOUCH_UI" "CarPi Touch User Interface       " \
		"WEB_UIs"  "Web Apps for external control    " \
		"MAINT_UI" "Maintenance User Interface       " \
		"EXIT"     "Return to main menu              " \
		3>&1 1>&2 2>&3)

	case $update_menu in
	DAEMONs)		
		downloadFile \
			"https://github.com/rGunti/CarPi/archive/develop.zip" \
			"$REPO_LOCAL_CACHE/daemons.zip" \
			"Downloading Daemon package from repository ..."
		
		unzipFile "daemons.zip"		
		
		runAutoScript \
			"./CarPi-develop/installer/auto/daemons.sh" \
			"./daemon-install.log" \
			"Updating Daemons ..."
		;;
	TOUCH_UI)
		downloadFile \
			"https://github.com/rGunti/CarPi/archive/develop.zip" \
			"$REPO_LOCAL_CACHE/ui.zip" \
			"Downloading Touch UI package from repository ..."
		
		unzipFile "ui.zip"		
		
		runAutoScript \
			"./CarPi-develop/installer/auto/ui.sh" \
			"./ui-install.log" \
			"Updating Touch UI ..."
		;;
	#WEB_UIs)
	#	;;
	#MAINT_UI)
	#	;;
	EXIT)
		#clear
		exit 0
		;;
	"")
		#clear
		exit 0
		;;
	*)
		whiptail \
		--title "Unimplemented Feature" \
		--backtitle "$BACKTITLE" \
		--msgbox "$update_menu has not been implemented yet. Sorry!" \
		0 0
		;;
	esac
done

