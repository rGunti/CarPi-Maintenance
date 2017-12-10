#!/bin/bash

VERSION=0.1
BACKTITLE="WiFi Editor Ver. $VERSION"

WIFI_SETTINGS_PATH=/boot/config/wifi/

SCREEN_WIDTH=53
SCREEN_HEIGHT=20
DIALOG_HEIGHT=$(expr $SCREEN_HEIGHT - 2)

export NCURSES_NO_UTF8_ACS=1

function add {
	interface=$(whiptail \
	--backtitle "$BACKTITLE" \
	--menu  "Select Interface:" \
	12 40 3 \
	"wlan1" "default                  " \
	"wlan2" "might not be installed   " \
	"wlan0" "Hotspot, not recommended " \
	3>&1 1>&2 2>&3)
	result=$?
	if [ $result -ne 0 ]; then
		return
	fi
	
	wifi_file="$WIFI_SETTINGS_PATH/$interface.conf"
	
	wifi_name=$(whiptail \
	--backtitle "$BACKTITLE" \
	--inputbox  "Enter SSID:" \
	8 30 \
	3>&1 1>&2 2>&3)
	result=$?
	if [ $result -ne 0 ]; then
		return
	fi
	
	select_wifi_type=$(whiptail \
	--backtitle "$BACKTITLE" \
	--menu  "Select encryption type for $wifi_name:" \
	12 40 3 \
	"WPA2" "Recommended              " \
	"NONE" "No encryption            " \
	3>&1 1>&2 2>&3)
	result=$?
	if [ $result -ne 0 ]; then
		return
	fi
	
	case $select_wifi_type in
	WPA2)
		wifi_pass=$(whiptail \
		--backtitle "$BACKTITLE" \
		--passwordbox "Enter the WiFi Password for $wifi_name:" \
		12 40 \
		3>&1 1>&2 2>&3)
		result=$?
		if [ $result = 0 ]; then
			wpa_passphrase "$wifi_name" "$wifi_pass" >> "$wifi_file"
			$result=?
			if [ $result -ne 0 ]; then
				whiptail \
				--backtitle "$BACKTITLE" \
				--msgbox "Failed to store credentials!" \
				12 40
			else
				whiptail \
				--backtitle "$BACKTITLE" \
				--msgbox "$wifi_name is registered" \
				12 40
			fi
		else
			return
		fi
		;;
	NONE)
		echo "" >> "$wifi_file"
		echo "network={" >> "$wifi_file"
		echo "ssid=\"$wifi_name\"" >> "$wifi_file"
		echo "key_mgmt=NONE" >> "$wifi_file"
		echo "}" >> "$wifi_file"
		
		whiptail \
		--backtitle "$BACKTITLE" \
		--msgbox "$wifi_name is registered" \
		12 40
		;;
	esac
}

function editWifi {
	interface=$(whiptail \
	--backtitle "$BACKTITLE" \
	--menu  "Select Interface:" \
	12 40 3 \
	"wlan1" "default                  " \
	"wlan2" "might not be installed   " \
	"wlan0" "Hotspot, not recommended " \
	3>&1 1>&2 2>&3)
	result=$?
	if [ $result -ne 0 ]; then
		return
	fi
	
	wifi_file="$WIFI_SETTINGS_PATH/$interface.conf"
	
	nano "$wifi_file"
}

while true; do
	WIFI_MENU=$(whiptail \
	--backtitle "$BACKTITLE" \
	--menu  "Select an option:" \
	12 40 3 \
	"ADD"    "Add WiFi Network    " \
	"EDIT"   "Edit / remove WiFi Network " \
	"EXIT"   "Quit WiFi Editor    " \
	3>&1 1>&2 2>&3)
	
	case $WIFI_MENU in
	ADD)
		add
		;;
	EDIT)
		editWifi
		;;
	EXIT)
		exit 0
		;;
	esac
done
