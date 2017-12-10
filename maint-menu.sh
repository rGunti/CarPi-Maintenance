#!/bin/bash

VERSION=0.1
BACKTITLE="CarPi Maintenance Mode Ver. $VERSION"

SCREEN_WIDTH=53
SCREEN_HEIGHT=20
DIALOG_HEIGHT=$(expr $SCREEN_HEIGHT - 2)

MAINT_START_FILE="/boot/start_maint"

export NCURSES_NO_UTF8_ACS=1

whiptail \
--backtitle "$BACKTITLE" \
--textbox ./res/welcome.msg \
$DIALOG_HEIGHT $SCREEN_WIDTH

while true; do
	MAIN_MENU=$(whiptail \
		--title "CarPi Maintenance Menu" \
		--backtitle "$BACKTITLE" \
		--menu  "$(cat ./res/main_menu.msg)" \
		$DIALOG_HEIGHT $SCREEN_WIDTH 8 \
		"SERVICES" "Configure Services" \
		"WIFI"     "Configure WiFi Settings" \
		"UPDATE"   "Check for software updates" \
		"EXIT"     "Reboot the system" \
		"EXIT_M"   "Quit Maint. Mode and Reboot      " \
		3>&1 1>&2 2>&3)

	case $MAIN_MENU in
	WIFI)
		./wifi.sh
		;;
	UPDATE)
		./update.sh
		;;
	EXIT)
		if (whiptail \
			--title "Reboot" \
			--backtitle "$BACKTITLE" \
			--yesno "Would you like to reboot the device? You will return back into maintenance mode." \
			9 $SCREEN_WIDTH) then
			{
				for ((i = 100 ; i >= 0 ; i-=5)); do
					sleep 0.1
					echo $i
				done
			} | whiptail \
				--backtitle "$BACKTITLE" \
				--gauge "CarPi is rebooting, please stand by..." \
				7 $SCREEN_WIDTH 100
			clear
			touch "$MAINT_START_FILE"
			reboot
			exit 0
		fi
		;;
	EXIT_M)
		if (whiptail \
			--title "Quit and Reboot" \
			--backtitle "$BACKTITLE" \
			--yesno "Would you really like to quit maintenance mode and reboot the device?" \
			9 $SCREEN_WIDTH) then
			{
				for ((i = 100 ; i >= 0 ; i-=5)); do
					sleep 0.1
					echo $i
				done
			} | whiptail \
				--backtitle "$BACKTITLE" \
				--gauge "CarPi is rebooting, please stand by..." \
				7 $SCREEN_WIDTH 100
			clear
			reboot
			exit 0
		fi
		;;
	"")
		clear
		exit 0
		;;
	*)
		;;
	esac
done
