#!/bin/bash
TIME_START="$(date -u +%s)"
echo $ELAPSED
echo "BMC power command by Kevin H. Cheong"
echo
echo "This script will scan BMC and send IPMI power command"
echo "It cannot detect BMC if BMC doesn't have default ADMIN IP/PWD"

BMCLIST=~/.bmclist

if [ ! -e $BMCLIST ]; then
  bmc_scan.sh
fi

VENDOR[0]="Inspur,admin,admin"
VENDOR[1]="Intel,root,superuser"
VENDOR[2]="Supermicro,ADMIN,ADMIN"
VENDOR[3]="IBM_X,admin,passw0rd"
VENDOR[4]="Lenovo,USERID,PASSW0RD"
VENDOR[5]="Dell,root,calvin"

if [ -z $2 ]; then
  DELAY=5
else
  DELAY=$2
fi

case $1 in
  "on")
    rm -f /root/.active
    ;;
  "reset")
    rm -f /root/.active
    ;;
  "cycle")
    rm -f /root/.active
    ;;
  "off")
    DELAY=0
    ;;
  "soft")
    DELAY=0
    ;;
  "status")
    DELAY=0
    ;;
esac

echo
echo "Delay between commands is $DELAY seconds"

cat $BMCLIST | while read line
do
  printf "%s\t" "$line"
  VENNAME=`echo "$line" | awk '{print $2}'`
  for (( l = 0; l < ${#VENDOR[@]}; l++ )); do
    if [[ ${VENDOR[$l]} =~ $VENNAME ]]; then
      VID=$l
      ipmitool -I lanplus -H $(echo $line | awk '{print $4}') -U $(echo ${VENDOR[$VID]} | cut -d',' -f2) -P  $(echo ${VENDOR[$VID]} | cut -d',' -f3) power $1
      sleep $DELAY
    fi
  done
done

if [ "$1" == "off" ] || [ "$1" == "soft" ]; then
  clear_dhcplease.sh
  rm -f ~/.active
fi
