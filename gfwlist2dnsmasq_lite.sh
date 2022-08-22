#!/bin/sh
#
# Update Time 2021.11.29 zhudan
# rm ipset too support clash dns
#
# Created Time: 2016.12.06 zhangzf
# Translate the gfwlist in base64 to dnsmasq rules with ipset
#

MYDNSIP=${2:-127.0.0.1}
MYDNSPORT=${3:-23453}
IPSETNAME=${4:-dnsmasq_gfw}

GFWURL="https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt"
GFW_TMP="/tmp/gfw.txt"
GFWLIST_TMP="/home/runner/work/publish/gfw.conf"
# DNSMASQ_GFW="/jffs/configs/dnsmasq.d/gfw.conf"

# curl & base64 command path
CURL=$(which curl)
CURLOPT="-s -k -o $GFW_TMP"

c_conf() {
	echo "# Updated on:$(date '+%F %T')" > $GFWLIST_TMP
	
	while read LINE; do 
		if [ "$(filter "$LINE")" -eq "0" ]; then
      			printf 'server=/.%s/%s#%s\n' $LINE $MYDNSIP $MYDNSPORT >> $GFWLIST_TMP
 			printf 'ipset=/.%s/%s\n' $LINE $IPSETNAME >> $GFWLIST_TMP
  		fi
	done
}

#排除某些规则
filter(){
	rule="$1"
	echo "$(echo "$rule" | grep -Ec "asuscomm\.com|asus\.com")"
}

addDomain(){
	echo "fast.com" >> $GFW_TMP
}

gen(){
	echo "开始下载GFW规则，过程可能较慢，请耐心等待"
	# download
	if [ ! -f $GFW_TMP ]; then
		$CURL $CURLOPT $GFWURL
		[ "$?" -eq 0 ] || {
			echo "Gfwlist download failed."
			exit 1
		}
	fi
	addDomain
	# parse gfwlist	
	cat $GFW_TMP \
		| grep -v \
			-e '^\s*$' \
			-e '^[\[!@@]' \
			-e '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]' \
		| sed \
			-e s'/^[@|]*//'g \
			-e s'/^http[s]*:\/\///'g \
			-e s'/[\/\%].*$//'g \
			-e s'/[^a-z]\+$//'g \
			-e s'/.*\*[^\.]*//'g \
			-e s'/^\.//'g 2>/dev/null \
		| grep -e '\.' \
		| sort -u \
		| c_conf
		
	rows=$(grep -c "$IPSETNAME" $GFWLIST_TMP)
	sed -i "1i# Rows:${rows}" $GFWLIST_TMP
	rm $GFW_TMP -f
	echo "更新GFW规则完毕"
}

#删除dns
del(){
	#rm -rf $DNSMASQ_GFW
	rm -rf $GFWLIST_TMP;
}

pwd
echo #################
ls -lah
command=$1
case $command in
	(gen)
		gen
		;;
	(del)
		del
		;;
	(*)
		echo "暂不支持该命令${command}，只支持gen、del"
		;;
esac
