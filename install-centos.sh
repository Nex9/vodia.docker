#
# Installer for Vodia PBX on CentOS
#
# TODO:
# Decide what languages you want installed (for audio). Valid languages are:
# dk: Danish
# nl: Dutch
# uk: English (UK)
# en: English (US)
# ca: French (Canada)
# fr: French (France)
# de: German
# gr: Greek
# it: Italian
# pl: Polish
# ru: Russian
# sp: Spanish
# se: Swedish
# tr: Turkish
LANGUAGES="en de"

# TODO:
# Decide where to put all the stuff:
PBX_DIR=/usr/local/pbx

# TODO:
# Decide which version you want to run:
VERSION=5.5.0

# Below here should be audomatic
# Find out if this is 32 or 64 bit:
BITS=`getconf LONG_BIT`;

DOWNLOAD_PATH=http://www.vodia.com/downloads/pbx

#
# Check if this is root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root"
  exit 1
fi

#
# Make sure that the programs that we need are installed:
#
if [ -z `which wget` ]; then
  yum install wget
fi
if [ -z `which ntpd` ]; then
  yum install ntp
fi
if [ -z `which unzip` ]; then
  yum install unzip
fi


if [ ! -d $PBX_DIR ]; then
  mkdir $PBX_DIR
fi
cd $PBX_DIR

# Get the language files:
for i in $LANGUAGES moh; do
  wget $DOWNLOAD_PATH/audio/audio_$i.zip
  unzip audio_$i.zip
  rm audio_$i.zip
done

# Get the executable:
wget $DOWNLOAD_PATH/centos$BITS/pbxctrl-centos$BITS-$VERSION
wget $DOWNLOAD_PATH/pbxctrl-$VERSION.dat

mv pbxctrl-centos$BITS-$VERSION pbxctrl
mv pbxctrl-$VERSION.dat pbxctrl.dat
chmod a+rx pbxctrl

# Install the startup script:
cd /etc/init.d
cat >pbx <<EOF
#!/bin/bash
#
# pbx	   This takes care of starting and stopping the Vodia PBX.
#
# chkconfig: - 20 80
# description: Vodia PBX PBX \\
# Vodia PBX is a software-based private branch exchange (PBX) for \\
# devices that support the SIP protocol. It provides telephony \\
# services as well as associated services like provisioning devices \\
# for telephony.


### BEGIN INIT INFO
# Provides: pbx
# Required-Start: \$network \$local_fs \$remote_fs
# Required-Stop: \$network \$local_fs \$remote_fs
# Should-Start: \$syslog \$named ntpdate
# Should-Stop: \$syslog \$named
# Short-Description: start and stop the Vodia PBX

# Description: Vodia PBX is a software-based private branch exchange
#              (PBX) for devices that support the SIP protocol. It
#              provides telephony services as well as associated
#              services like provisioning devices for telephony.

### END INIT INFO

# Source function library.
. /etc/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

PBX_DIR=$PBX_DIR
prog=\$PBX_DIR/pbxctrl
lockfile=/var/lock/subsys/pbxctrl
OPTIONS="--dir \$PBX_DIR"

start() {
	[ "\$EUID" != "0" ] && exit 4
	[ "\$NETWORKING" = "no" ] && exit 1
	[ -x \$prog ] || exit 5

        # Start daemons.
        echo -n \$"Starting \$prog: "
        daemon \$prog \$OPTIONS
	RETVAL=\$?
        echo
	[ \$RETVAL -eq 0 ] && touch \$lockfile
	return \$RETVAL
}

stop() {
	[ "\$EUID" != "0" ] && exit 4
        echo -n \$"Shutting down \$prog: "
	killproc \$prog
	RETVAL=\$?
        echo
	[ \$RETVAL -eq 0 ] && rm -f \$lockfile
	return \$RETVAL
}

# See how we were called.
case "\$1" in
  start)
	start
	;;
  stop)
	stop
	;;
  status)
	status \$prog
	;;
  restart|force-reload)
	stop
	start
	;;
  try-restart|condrestart)
	if status \$prog > /dev/null; then
	    stop
	    start
	fi
	;;
  reload)
	exit 3
	;;
  *)
	echo \$"Usage: \$0 {start|stop|status|restart|try-restart|force-reload}"
	exit 2
esac

EOF

chmod a+rx pbx
chkconfig --add pbx
chkconfig --level 3 pbx on
# service pbx start

# iptables
#

echo 'IMPORTANT:'
echo 'You might have to edit your firewall settings. Consider'
echo '"service iptables stop" and "chkconfig iptables off" to'
echo 'see if you need to edit the iptables configuration to use'
echo 'the PBX service'
