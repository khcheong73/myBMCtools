#!/bin/bash
SECONDS=0
if [ -z $1 ]; then
  echo "BMC scanner by Kevin H. Cheong"
  echo
  echo "This script will scan BMC IP address & MAC address on network"
  echo "And it cannot detect BMC if BMC doesn't have default ADMIN IP/PWD in script"
  echo
  echo "Scanning ..."
fi

VENDOR[0]="Inspur,admin,admin,6C:92:BF\|B4:05:5D"
VENDOR[1]="Intel,root,superuser,A4:BF:01"
VENDOR[2]="Supermicro,ADMIN,ADMIN,0C:C4:7A\|00:25:90"
VENDOR[3]="IBM_X,admin,passw0rd,98:BE:94"
VENDOR[4]="Lenovo,USERID,PASSW0RD,7C:D3:0A\|08:94:EF"

COUNT=0;

rm -f ~/.bmclist > /dev/null

for i in `ip -f inet addr | grep "state UP" | grep -v "lo\|virbr" | cut -d":" -f2`; do
  BRDNOW=`ip -f inet addr show dev $i | grep inet | awk '{print $4}' | xargs -n1 | sort -u | xargs`
  if [[ "$BRDOLD" =~ "$BRDNOW" ]]; then
    echo
  else
    BRDOLD=$BRDOLD" "$BRDNOW
#    echo $BRDOLD

  for j in `ip -f inet addr show dev $i | grep inet | awk '{print $2}'`; do
    echo; echo [ $i: $j ]
    for (( l = 0; l < ${#VENDOR[@]}; l++ )); do
      for k in `nmap --system-dns -sP $j | grep -B2 -i "$(echo ${VENDOR[$l]}| cut -d',' -f4)" | grep Nmap | awk '{print $NF}' | sed 's/.*\[\([^]]*\)\].*/\1/g'`; do
#        echo $k
        INFO=`timeout 2 ipmitool -I lanplus -H $k -U $(echo ${VENDOR[$l]} | cut -d',' -f2) -P  $(echo ${VENDOR[$l]} | cut -d',' -f3) lan print 2>&1 | grep "IP Address\|MAC Address" | grep -v "Source" | awk '{print $NF}'`
        if [ ! -z "${INFO}" ]; then
          COUNT=$((COUNT+1))
          SN=$(ipmitool -I lanplus -H $k -U $(echo ${VENDOR[$l]} | cut -d',' -f2) -P  $(echo ${VENDOR[$l]} | cut -d',' -f3) fru 2>&1 | grep -m1 -i "Product Serial" | awk '{print $4}' &)
          if [ -z "$SN" ]; then SN="n/a"; fi
          PN=$(ipmitool -I lanplus -H $k -U $(echo ${VENDOR[$l]} | cut -d',' -f2) -P  $(echo ${VENDOR[$l]} | cut -d',' -f3) fru 2>&1 | grep -m1 -i "Product Name" | cut -d':' -f2 &)
          if [ -z "$PN" ]; then PN="n/a"; fi
          printf "%02d %-10s %-10s  %-15s  %s  %s\n" $COUNT $(echo ${VENDOR[$l]} | cut -d',' -f1) $SN $INFO "$(echo $PN)" 2>&1 | tee -a ~/.bmclist
        fi
      done
    done
  done
  fi
done

if [ -z $1 ]; then
  echo
  echo "# of detected BMC = "$COUNT
  echo Completed in $SECONDS secs
fi
