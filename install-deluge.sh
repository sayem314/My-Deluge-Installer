#!/bin/bash
#
# My Deluge Installer
#

#Global Config
init=`cat /proc/1/comm`
ip=`wget -qO- ipv4.icanhazip.com`
user=`whoami`
nocert="--no-check-certificate"
bashname=$(basename $BASH_SOURCE)

howto () {
	echo ""
	echo " To install, run"
	echo " $bashname -install"
	echo ""
	echo " To uninstall, run"
	echo " $bashname -uninstall"
	echo ""
}

chksudo () {
	if [[ "$EUID" -ne 0 ]]; then
		echo ""
		echo " Sorry, you need to run this as root"
		echo ""
		exit
	fi
}

installdeluge () {
	if [[ -e /etc/systemd/system/deluge.service || -e /etc/init/deluge.conf|| -e /etc/default/deluge-daemon ]]; then
		echo ""
		echo " Deluge is already installed"
		echo ""
		exit
	fi

	echo ""
	echo -n " Installing python-software-properties..."
	apt-get install python-software-properties -y &>/dev/null
	echo "  $(tput setaf 2)DONE$(tput sgr0)"
	echo -n " Addning repository ppa:deluge-team/ppa..."
	yes ENTER | add-apt-repository ppa:deluge-team/ppa &>/dev/null
	echo "  $(tput setaf 2)DONE$(tput sgr0)"
	echo -n " Upadting repository..."
	apt-get update -y &>/dev/null
	echo "  $(tput setaf 2)DONE$(tput sgr0)"
	echo -n " Installing deluged deluge-webui..."
	apt-get install deluged deluge-webui -y &>/dev/null
	echo "  $(tput setaf 2)DONE$(tput sgr0)"
	echo ""
	
	# Starting Service
	makeservice;
	#deluged
	#deluge-web --fork
	echo ""
	invoke-rc.d deluge-daemon start
	echo ""
	echo " Access deluge at $(tput setaf 3)http://$ip:8112$(tput sgr0)"
	echo " Default deluge password is $(tput setaf 3)deluge$(tput sgr0)"
	echo ""

}

makeservice () {
	rm -f /etc/default/deluge-daemon
	cat <<EOF > /etc/default/deluge-daemon
# Configuration for /etc/init.d/deluge-daemon
# The init.d script will only run if this variable non-empty.
DELUGED_USER="root"
# Should we run at startup?
RUN_AT_STARTUP="YES"
EOF
	wget -q $nocert https://raw.githubusercontent.com/sayem314/My-Deluge-Installer/master/etc/deluge-daemon -O /etc/init.d/deluge-daemon
	chmod +x /etc/init.d/deluge-daemon
	update-rc.d deluge-daemon defaults
}

uninstalldeluge () {
	if [[ -e /etc/systemd/system/deluge.service || -e /etc/init/deluge.conf|| -e /etc/default/deluge-daemon ]]; then
		echo ""
		echo " Are you sure you want to uninstall Deluge? [y/N]"
		read -p " Select an option: " option
		case $option in
			[yY][eE][sS]|[yY])
			echo ""
			echo " Stopping deluge process"
			killall deluged
			killall deluge-web
			if [ "$init" == 'systemd' ]; then
			systemctl disable deluge
			rm -f /etc/systemd/system/deluge.service
			elif [ "$init" == 'init' ]; then
			rm -f /etc/init/deluge.conf
			fi
			echo ""
			echo " Uninstalling deluge"
			rm -f /etc/default/deluge-daemon
			rm -f /etc/init.d/deluge-daemon
			update-rc.d -f deluge-daemon remove
			apt-get remove --purge deluged deluge-webui -y &>/dev/null
			apt-get autoremove -y &>/dev/null
			apt-get autoclean -y &>/dev/null
			echo " Deluge Uninstalled"
			echo ""
			exit
			;;
			[nN][oO]|[nN]) echo ""; exit;;
			*) echo ""; echo " Incorrect input, exiting! "; echo "";;
		esac
		else
		echo ""
		echo "  Looks like Deluge is not installed"
		echo ""
	fi
}

# See how we were called.
case $1 in
	'-install'|'install' )
	chksudo; installdeluge;;
	'-del'|'delete'|'-rm'|'-uninstall'|'uninstall' )
	chksudo; uninstalldeluge;;
	*)
	howto;;
esac
exit 1
