#!/bin/bash
SECONDS=0
  echo "BMC scanner by Kevin H. Cheong"
  echo
  echo "This script will scan BMC IP address & MAC address on network"
  echo "And it cannot detect BMC if BMC doesn't have default ADMIN IP/PWD in script"
  echo

ETHS=`ip -f inet addr | grep "state UP" | grep -v "lo\|virbr" | cut -d":" -f2`

function bmcscan() {
  echo "Scanning ..."

  VENDOR[0]="Inspur,admin,admin,6C:92:BF\|B4:05:5D"
  VENDOR[1]="Intel,root,superuser,A4:BF:01\|72:5D:CC"
  VENDOR[2]="Supermicro,ADMIN,ADMIN,0C:C4:7A\|00:25:90"
  VENDOR[3]="IBM_X,admin,passw0rd,98:BE:94"
  VENDOR[4]="Lenovo,USERID,PASSW0RD,7C:D3:0A\|08:94:EF\|6C:AE:8B"
  VENDOR[5]="Dell,root,calvin,70:B5:E8\|2C:EA:7F\|4C:D9:8F\|F4:02:70\|6E:47:A6\|58:8A:5A\|B0:7B:25\|90:B1:1C\|EC:2A:72\|18:FB:7B\|B0:7B:25"

  COUNT=0;

  rm -f ~/.bmclist > /dev/null

  if [[ $1 == "all" ]]; then
    IFT="$ETHS"
  else
    IFT=$1
  fi

  for i in $IFT; do
    BRDNOW=`ip -f inet addr show dev $i | grep inet | awk '{print $4}' | xargs -n1 | sort -u | xargs`
    if [[ "$BRDOLD" =~ "$BRDNOW" ]]; then
      echo
    else
      BRDOLD=$BRDOLD" "$BRDNOW
      for j in `ip -f inet addr show dev $i | grep inet | awk '{print $2}'`; do
        MAP=`nmap --system-dns -sP $j`
        echo; echo [ $i: $j ]
        for (( l = 0; l < ${#VENDOR[@]}; l++ )); do
          BMCID=$(echo ${VENDOR[$l]} | cut -d',' -f2)
          BMCPWD=$(echo ${VENDOR[$l]} | cut -d',' -f3)
          VENMAC=$(echo ${VENDOR[$l]} | cut -d',' -f4)
#         echo $l $BMCID $BMCPWD
          for k in `echo "$MAP" | grep -B2 -i "$VENMAC" | grep Nmap | awk '{print $NF}' | cut -d'(' -f2 | cut -d')' -f1`; do
#          echo $k
            MAC=`timeout 2 ipmitool -I lanplus -H $k -U $BMCID -P $BMCPWD lan print 2>&1 | grep "MAC Address" | awk '{print $NF}'`
            #INFO=`timeout 2 ipmitool -I lanplus -H $k -U $BMCID -P $BMCPWD lan print 2>&1 | grep "IP Address\|MAC Address" | grep -v "Source" | awk '{print $NF}'`
            #if [ ! -z "${INFO}" ]; then
            if [ ! -z "${MAC}" ]; then
              COUNT=$((COUNT+1))
              SN=$(ipmitool -I lanplus -H $k -U $BMCID -P $BMCPWD fru 2>&1 | grep -m1 -i "Product Serial" | awk '{print $4}' &)
              if [ -z "$SN" ]; then SN="n/a"; fi
              PN=$(ipmitool -I lanplus -H $k -U $BMCID -P $BMCPWD fru 2>&1 | grep -m1 -i "Product Name" | cut -d':' -f2 &)
              if [ -z "$PN" ]; then PN="n/a"; fi
              #printf "%02d %-10s %-10s  %-15s  %s  %s\n" $COUNT $(echo ${VENDOR[$l]} | cut -d',' -f1) $SN $INFO "$(echo $PN)" 2>&1 | tee -a ~/.bmclist
              printf "%02d %-10s %-10s  %-15s  %s  %s\n" $COUNT $(echo ${VENDOR[$l]} | cut -d',' -f1) $SN $k $MAC "$(echo $PN)" 2>&1 | tee -a ~/.bmclist
            fi
          done
        done
      done
    fi
  done

  echo
  echo "# of detected BMC = "$COUNT
  echo Completed in $SECONDS secs
}


## MAIN
if [ -z $1 ]; then
  echo "No interface assigned"
  echo $0 "[interface name] or all"
  for i in $ETHS; do
    for j in `ip -f inet addr show dev $i | grep inet | awk '{print $2}'`; do
      echo " "$i: $j
    done
  done
  exit
else
  if [[ "$ETHS" =~ $1 ]] || [[ $1 == "all" ]]; then
    bmcscan $1
  else
    echo "Wrong interface assigned"
    exit
  fi
fi
