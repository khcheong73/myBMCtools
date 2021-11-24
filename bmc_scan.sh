#!/bin/bash
TIME_START="$(date -u +%s)"
if [ -z $1 ]; then
  echo "BMC scanner by Kevin H. Cheong"
  echo
  echo "This script will scan BMC IP address & MAC address on network"
  echo "And it cannot detect BMC if BMC doesn't have default ADMIN IP/PWD in script"
  echo
  echo "Scanning ..."
  echo
fi

VENDOR[0]="Inspur,admin,admin,6C:92:BF\|B4:05:5D"
VENDOR[1]="Intel,root,superuser,A4:BF:01"
VENDOR[2]="Supermicro,ADMIN,ADMIN,0C:C4:7A"
VENDOR[3]="IBM_X,admin,passw0rd,98:BE:94"
VENDOR[4]="Lenovo,USERID,PASSW0RD, 7C:D3:0A"

COUNT=0;

rm -f ~/diskless/.bmclist > /dev/null

for i in `ip -f inet addr | grep "state UP" | grep -v "lo\|virbr\|wlan" | cut -d":" -f2`; do
  echo $i
  for j in `ip -f inet addr show dev $i | grep inet | awk '{print $2}'`; do
    echo $j
    for (( l = 0; l < ${#VENDOR[@]}; l++ )); do
      for k in `nmap --system-dns -sP $j | grep -B2 -i "$(echo ${VENDOR[$l]}| cut -d',' -f4)" | grep Nmap | awk '{print $5}'`; do
        INFO=`timeout 2 ipmitool -I lanplus -H $k -U $(echo ${VENDOR[$l]} | cut -d',' -f2) -P  $(echo ${VENDOR[$l]} | cut -d',' -f3) lan print 2>&1 | grep "IP Address\|MAC Address" | grep -v "Source" | awk '{print $4}'`
        if [ ! -z "${INFO}" ]; then
          COUNT=$((COUNT+1))
          SN=$(ipmitool -I lanplus -H $k -U $(echo ${VENDOR[$l]} | cut -d',' -f2) -P  $(echo ${VENDOR[$l]} | cut -d',' -f3) fru 2>&1 | grep -m1 -i "Product Serial" | awk '{print $4}' &)
          if [ -z "$SN" ]; then SN="n/a"; fi
          PN=$(ipmitool -I lanplus -H $k -U $(echo ${VENDOR[$l]} | cut -d',' -f2) -P  $(echo ${VENDOR[$l]} | cut -d',' -f3) fru 2>&1 | grep -m1 -i "Product Name" | awk '{print $4}' &)
          if [ -z "$PN" ]; then PN="n/a"; fi
          printf "%02d %-10s %-9s  %-15s  %s  %s\n" $COUNT $(echo ${VENDOR[$l]} | cut -d',' -f1) $SN $INFO "$PN" 2>&1 | tee -a ~/diskless/.bmclist
        fi
      done
    done
  done
done

TIME_END="$(date -u +%s)"
ELAPSED="$(($TIME_END - $TIME_START))"

if [ -z $1 ]; then
  echo
  echo "# of detected BMC = "$COUNT
  echo Completed in $ELAPSED secs
fi
