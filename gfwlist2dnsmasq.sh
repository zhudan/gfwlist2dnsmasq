#!/bin/sh
#
# Created Time: 2016.12.06 zhangzf
# Translate the gfwlist in base64 to dnsmasq rules with ipset
#

MYDNSIP='127.0.0.1'
MYDNSPORT='23453'
# IPSETNAME='gfwlist'

GFWURL="https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
GFWLIST_TMP="/tmp/gfwlist.txt"
GFWLIST_D_TMP=$(mktemp)

# curl & base64 command path
CURL=$(which curl)
CURLOPT="-s -k -o $GFWLIST_TMP"
BASE64=$(which base64)

c_conf() {
	echo "# Updated on $(date '+%F %T')" >$GFWLIST_D_TMP
	
	cat <<-EOF >>$GFWLIST_D_TMP
	$(while read LINE; do \
		printf 'server=/.%s/%s#%s\n' $LINE $MYDNSIP $MYDNSPORT; \
# 		printf 'ipset=/.%s/%s\n' $LINE $IPSETNAME; \
	done)
EOF
}

# download
if [ ! -f $GFWLIST_TMP ]; then
	$CURL $CURLOPT $GFWURL
	[ "$?" -eq 0 ] || {
		echo "Gfwlist download failed."
		exit 1
	}
fi

# parse gfwlist	
$BASE64 -d $GFWLIST_TMP \
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

# cp $GFWLIST_D_TMP ./dnsmasq_gfwlist.conf -f

# rm $GFWLIST_D_TMP -f
