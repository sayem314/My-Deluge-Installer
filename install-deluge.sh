#!/bin/bash
#
# My Deluge Installer
# v1.0
#

#Global Config
init=`cat /proc/1/comm`
ip=`wget -qO- ipv4.icanhazip.com`
user=`whoami`
nocert="--no-check-certificate"

	if [[ -e /etc/systemd/system/deluge.service ]]; then
		echo ""
		echo "  Deluge is already installed"
		echo ""
		exit
	elif [[ -e /etc/init/deluge.conf ]]; then
		echo ""
		echo "  Deluge is already installed"
		echo ""
		exit
	fi

	if [[ "$EUID" -ne 0 ]]; then
		echo ""
		echo "  Sorry, you need to run this as root"
		exit
	fi

	echo ""
	echo "  Installing deluge"
	apt-get update -qy &>/dev/null && apt-get install deluged deluge-webui -qy &>/dev/null
	echo "  Deluge Installed"
	
	# Creating Service
	if [ "$init" == 'systemd' ]; then
	rm /etc/systemd/system/deluge.service
	wget $nocert "https://raw.githubusercontent.com/sayem314/My-Deluge-Installer/master/etc/deluge.service" -O "/etc/systemd/system/deluge.service"
	systemctl enable deluge
	elif [ "$init" == 'init' ]; then
	rm /etc/init/deluge.conf
	wget $nocert "https://raw.githubusercontent.com/sayem314/My-Deluge-Installer/master/etc/deluge.conf" -O "/etc/init/deluge.conf"
	fi
	service deluge start
	echo ""
	echo "  Access deluge at $(tput setaf 3)http://$ip:8112$(tput sgr0)"
	echo "  Default deluge password is $(tput setaf 3)deluge$(tput sgr0)"
	echo ""
	exit
