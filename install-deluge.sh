#!/bin/bash
#
# My Deluge Installer
#

#Global Config
init=`cat /proc/1/comm`
ip=`wget -qO- ipv4.icanhazip.com`
user=`whoami`
nocert="--no-check-certificate"

howto () {
	echo ""
	echo "  use -install or -del"
	echo ""
}

chksudo () {
	timeout 2 sudo id &>/dev/null && permission="true" || permission="no"
	if [[ "$permission" == "no" ]]; then
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
	echo -n "  Installing deluge"
	apt-get install python-software-properties -y &>/dev/null
	yes ENTER | add-apt-repository ppa:deluge-team/ppa &>/dev/null
	apt-get update -y &>/dev/null
	apt-get install deluged deluge-webui -y &>/dev/null
	echo "  $(tput setaf 2)DONE$(tput sgr0)"
	
	# Starting Service
	deluged
	deluge-web --fork
	echo ""
	echo "  Access deluge at $(tput setaf 3)http://$ip:8112$(tput sgr0)"
	echo "  Default deluge password is $(tput setaf 3)deluge$(tput sgr0)"
	echo ""

}

makeservice () {
	echo "  Not implented yet"
	exit;
	echo -n "  Creating service..."
	if [ "$init" == 'systemd' ]; then
		rm -f /etc/systemd/system/deluge.service
		cat <<EOF > /etc/systemd/system/deluge.service
[Unit]
Description=Deluge Bittorrent Client Web Interface
After=network-online.target

[Service]
Type=simple
User=$user
Group=$user
UMask=027
ExecStart=/usr/bin/deluge-web
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
		chmod 0644 /etc/systemd/system/deluge.service
		echo "  $(tput setaf 2)DONE$(tput sgr0)"
		systemctl enable deluge
	elif [[ "$init" == 'init' ]]; then
		rm -f /etc/init/deluge.conf
		cat <<EOF > /etc/init/deluge.conf
start on started deluge
stop on stopping deluge

env uid=$user
env gid=$user
env umask=027

exec start-stop-daemon -S -c $uid:$gid -k $umask -x /usr/bin/deluge-web
EOF
		echo "  $(tput setaf 2)DONE$(tput sgr0)"
	else
		echo "  $(tput setaf 1)FAILED$(tput sgr0)"

	fi
}

uninstalldeluge () {
	# Deleting Service
	echo ""
	echo "  Stopping deluge process"
	service deluged stop
	killall deluged
	killall deluge-web
	if [ "$init" == 'systemd' ]; then
	systemctl disable deluge
	rm -f /etc/systemd/system/deluge.service
	elif [ "$init" == 'init' ]; then
	rm -f /etc/init/deluge.conf
	fi
	echo ""
	echo "  Uninstalling deluge"
	apt-get remove --purge deluged deluge-webui -y &>/dev/null
	apt-get autoremove -y &>/dev/null
	apt-get autoclean -y &>/dev/null
	echo "  Deluge Uninstalled"
	echo ""
	exit
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
