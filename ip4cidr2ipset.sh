#!/bin/sh

cidrfile="/home/runner/work/publish/ip-cidr.ipset"

echo "create ad hash:net family inet hashsize 1024 maxelem 65536" > $cidrfile

#开始添加需要走代理的ip-cidr
add_telegram(){
  echo 开始添加telegram ip-cidr
  curl -s -k -o /home/runner/work/publish/telegramcidr.txt https://raw.githubusercontent.com/Loyalsoldier/clash-rules/release/telegramcidr.txt
  sed -i "s/payload://g;s/  - //g;s/'//g;/^\s*$/d" /home/runner/work/publish/telegramcidr.txt
  lines=$(cat /home/runner/work/publish/telegramcidr.txt | awk '{print $0}')
  for line in $lines
  do
    detect_ip ${line}
    d=$?
    if [ $d -eq 4 ]; then
      #echo "为合法IPV4格式，进行处理" >> $LOG_FILE
      echo add ad ${line} >> $cidrfile
    elif [ $d -eq 6 ]; then
      #echo "为合法IPV6格式，进行处理" >> $LOG_FILE
      continue
    fi
  done
}

detect_ip(){
	IPADDR=$1
	regex_v4="((2[0-4][0-9]|25[0-5]|1[0-9][0-9]|[1-9]?[0-9])(\.(2[0-4][0-9]|25[0-5]|1[0-9][0-9]|[1-9]?[0-9])){3}(\/([1-9]|[1-2]\d|3[0-2])$)?)"
	regex_v6="(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))"
	ckStep4=`echo $1 | egrep $regex_v4 | wc -l`
	ckStep6=`echo $1 | egrep $regex_v6 | wc -l`
	if [ $ckStep4 -eq 0 ]; then
		if [ $ckStep6 -eq 0 ]; then
			return 1
		else
			return 6
		fi
	else
		return 4
	fi
}

add_telegram
