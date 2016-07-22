#!/bin/bash
#
# My Deluge Installer
#

#Global Config
init=`cat /proc/1/comm`
ip=`wget -qO- ipv4.icanhazip.com`
user=`whoami`
nocert="--no-check-certificate"

amiroot () {
	echo ""
	echo "  use -install or -del"
	echo ""
}

amiroot () {
	if [[ "$EUID" -ne 0 ]]; then
		echo ""
		echo "  Sorry, you need to run this as root"
		exit
	fi
}

installdeluge () {
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

	echo ""
	echo "  Installing deluge"
	dpkg --configure -a &>/dev/null
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
}

uninstalldeluge () {
	# Deleting Service
	echo ""
	echo "  Stopping deluge process"
	service deluge stop
	if [ "$init" == 'systemd' ]; then
	systemctl disable deluge
	rm /etc/systemd/system/deluge.service
	elif [ "$init" == 'init' ]; then
	rm /etc/init/deluge.conf
	fi
	echo ""
	echo "  Uninstalling deluge"
	dpkg --configure -a &>/dev/null
	apt-get remove --purge deluged deluge-webui -y &>/dev/null
	apt-get autoremove &>/dev/null
	apt-get autoclean &>/dev/null
	echo "  Deluge Uninstalled"
	echo ""
	exit
}

# See how we were called.
case $1 in
	'-install'|'install' )
		amiroot; installdeluge;;
	'-del'|'delete'|'-rm'|'-uninstall'|'uninstall' )
		amiroot; uninstalldeluge;;
	*)
		error;;
esac
exit 1
