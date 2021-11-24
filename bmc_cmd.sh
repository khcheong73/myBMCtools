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

VENDOR[0]="Inspur,admin,admin,6C:92:BF\|B4:05:5D"
VENDOR[1]="Intel,root,superuser,A4:BF:01"
VENDOR[2]="Supermicro,ADMIN,ADMIN,0C:C4:7A"
VENDOR[3]="IBM_X,admin,passw0rd,98:BE:94"

cat $BMCLIST | while read line
do
  printf "%s\t" "$line"
  for (( l = 0; l < ${#VENDOR[@]}; l++ )); do
    VENNAME=`echo "$line" | awk '{print $2}'`
    if [ $VENNAME == ${VENDOR[$l]} ]; then
      VID=$l
    fi      
  done
  ipmitool -I lanplus -H $(echo $line | awk '{print $4}') -U $(echo ${VENDOR[$VID]} | cut -d',' -f2) -P  $(echo ${VENDOR[$VID]} | cut -d',' -f3) $1 $2 $3 $4 $5 
done



