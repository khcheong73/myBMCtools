#!/bin/bash
echo $ELAPSED
echo "BMC command by Kevin H. Cheong"
echo
echo "This script will scan BMC and send IPMI command"
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

cat $BMCLIST | while read line
do
  printf "%s\n" "$line"
  VENNAME=`echo "$line" | awk '{print $2}'`
  for (( l = 0; l < ${#VENDOR[@]}; l++ )); do
    if [[ ${VENDOR[$l]} =~ $VENNAME ]]; then
      VID=$l
      ipmitool -I lanplus -H $(echo $line | awk '{print $4}') -U $(echo ${VENDOR[$VID]} | cut -d',' -f2) -P  $(echo ${VENDOR[$VID]} | cut -d',' -f3) $1 $2 $3 $4 $5
      echo
    fi
  done
done
