#!/bin/bash
TIME_START="$(date -u +%s)"
echo $ELAPSED
echo "BMC power command by Kevin H. Cheong"
echo
echo "This script will scan BMC and send IPMI power command" 
echo "It cannot detect BMC if BMC doesn't have default ADMIN IP/PWD"

BMCLIST=~/diskless/.bmclist

if [ ! -e $BMCLIST ]; then
  bmc_scan.sh
fi

VENDOR[0]="Inspur,admin,admin,6C:92:BF\|B4:05:5D"
VENDOR[1]="Intel,root,superuser,A4:BF:01"
VENDOR[2]="Supermicro,ADMIN,ADMIN,0C:C4:7A"
VENDOR[3]="IBM_X,admin,passw0rd,98:BE:94"

if [ -z $2 ]; then
  DELAY=5
else
  DELAY=$2
fi

case $1 in
  "on")
    rm -f /root/diskless/.active
    ;;
  "reset")
    rm -f /root/diskless/.active
    ;;
  "cycle")
    rm -f /root/diskless/.active
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
  for (( l = 0; l < ${#VENDOR[@]}; l++ )); do
    VENNAME=`echo "$line" | awk '{print $2}'`
    if [ $VENNAME == ${VENDOR[$l]} ]; then
      VID=$l
    fi      
  done
  ipmitool -I lanplus -H $(echo $line | awk '{print $4}') -U $(echo ${VENDOR[$VID]} | cut -d',' -f2) -P  $(echo ${VENDOR[$VID]} | cut -d',' -f3) power $1 
  sleep $DELAY 
done

if [ "$1" == "off" ] || [ "$1" == "soft" ]; then
  clear_dhcplease.sh
  rm -f ~/diskless/.active
fi



