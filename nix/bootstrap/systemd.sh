#!/bin/bash

##
# (c) 2018 42Gears Mobility Systems Pvt Ltd. All Rights Reserved.
##

BASHNAME=`basename "$0"`
if [ "$BASHNAME" == "systemd.sh" ]; then
  RED='\033[0;31m'
  NC='\033[0m'
  echo -e "${RED}Invalid Usage of $BASHNAME. Please execute 'installnix.sh' instead.${NC}"
  exit 127
fi

# Check if systemd is installed.
SYSTEMDBIN="$(type -p systemctl)"
if [ -z "$SYSTEMDBIN" ]; then
  echo -e "${RED}This installer is not supported on this platform.${NC}"
  exit 127
fi

# Copy Upstart relatd files

NIXSERVICEFILE_S="$ABSDIR/bootstrap/nix.service"
NIXROBOTSERVICEFILE_S="$ABSDIR/bootstrap/nixr.service"

NIXSERVICEFILE_D="/lib/systemd/system/nix.service"
NIXROBOTSERVICEFILE_D="/lib/systemd/system/nixr.service"

# Check if systemd service is available
if [ ! -d "/lib/systemd/system" ]; then
  #suse has systemd in usr/lib/systemd/system
  if [ -d "/usr/lib/systemd/system" ];then
    NIXSERVICEFILE_D="/usr/lib/systemd/system/nix.service"
    NIXROBOTSERVICEFILE_D="/usr/lib/systemd/system/nixr.service"
  else
    echo -e "${RED}Cannot find /lib/systemd/system or usr/lib/systemd/system to install Service.${NC}"
    exit 1
  fi
fi

# Print service status and stop it

systemctl stop nix.service 
systemctl stop nixr.service

cp $NIXSERVICEFILE_S $NIXSERVICEFILE_D
cp $NIXROBOTSERVICEFILE_S $NIXROBOTSERVICEFILE_D

chmod 0640 $NIXSERVICEFILE_D
chown root:root $NIXSERVICEFILE_D

chmod 0640 $NIXROBOTSERVICEFILE_D
chown root:root $NIXROBOTSERVICEFILE_D

# Replace in config files
WORKDIRESC=$(echo "$WORKDIR" | sed 's/\//\\\//g')
STARTCMD="$JAVABIN -jar $NIXJARFILE_D"
STARTCMD=$(echo "$STARTCMD" | sed 's/\//\\\//g')

STARTROBOTCMD="$JAVABIN -jar $NIXROBOTJARFILE_D"
STARTROBOTCMD=$(echo "$STARTROBOTCMD" | sed 's/\//\\\//g')
WORKDIRESCEVE="$WORKDIRESC\/nix.eve"

sed -i "s/\("WorkingDirectory" *= *\).*\$/\1$WORKDIRESC/" $NIXSERVICEFILE_D
sed -i "s/\("EnvironmentFile" *= *\).*\$/\1$WORKDIRESCEVE/" $NIXSERVICEFILE_D
sed -i "s/\("ExecStart" *= *\).*\$/\1$STARTCMD/" $NIXSERVICEFILE_D

sed -i "s/\("WorkingDirectory" *= *\).*\$/\1$WORKDIRESC/" $NIXROBOTSERVICEFILE_D
sed -i "s/\("EnvironmentFile" *= *\).*\$/\1$WORKDIRESCEVE/" $NIXROBOTSERVICEFILE_D
sed -i "s/\("ExecStart" *= *\).*\$/\1$STARTROBOTCMD/" $NIXROBOTSERVICEFILE_D

X11DISPLAYPROPERTY=${DQT}"XAUTHORITY=$X11DISPLAYDIR"${DQT}" "${DQT}"DISPLAY=$X11DISPLAYVAL"${DQT}
X11DISPLAYPROPERTY=$(echo "$X11DISPLAYPROPERTY" | sed 's/\//\\\//g')
sed -i "s/\("Environment" *= *\).*\$/\1$X11DISPLAYPROPERTY/" $NIXROBOTSERVICEFILE_D

# Reload and Start Service
systemctl daemon-reload

systemctl enable nix.service
systemctl enable nixr.service

systemctl start nix.service 
systemctl start nixr.service

systemctl status nix.service
systemctl status nixr.service
