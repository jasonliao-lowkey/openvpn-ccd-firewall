#!/bin/bash
# ./defaultrule.sh init
# clean rule and init
# 這隻寫超過10年以上了，一直以來都是自用，因某些原因就公開了吧
# made by JasonLiao, 2023/03/10
iptable=/sbin/iptables
AWK=/usr/bin/awk
CHMOD="/bin/chmod"
function cltabl(){
	$iptable -S "${1}" >/dev/null 2>&1 ; return=$?
        if [ "$INIT" -eq 1 ] ; then
		if [ $return == 0 ] ; then 
			$iptable -F "${1}"  || echo "Fail -F ${1} #1"
			$iptable -X "${1}" || echo "Fail -X ${1}"
		fi
                $iptable -N "${1}" || echo "Fail -N ${1} #1" 
        	$iptable -I openvpn -m recent --rcheck --name ${1} -g ${1} || echo "Fail -I openvpn recent ${1} #1" 
#		$CHMOD 666 /proc/net/xt_recent/${1}
		# remove above , because setup add option in /etc/modprobe.d/netfitler.conf of pve host , "options xt_recent ip_list_tot=16384 ip_list_perms=0666"
		
	else
		if [ $return == 1 ] ; then  
			$iptable -N ${1} || echo "Fail -N ${1} #2"
			$iptable -I openvpn -m recent --rcheck --name ${1} -g ${1} || echo "Fail -I openvpn recent ${1} #2" 
#			$CHMOD 666 /proc/net/xt_recent/${1}
			# remove above , because setup add option in /etc/modprobe.d/netfitler.conf of pve host , "options xt_recent ip_list_tot=16384 ip_list_perms=0666"
		else
			$iptable -F "${1}"  || echo "Fail -F ${1} #2"
		fi
        fi

        $AWK '{ if ( $1 ~ "push" ){ split($4,mask,"\""); printf("%s/%s\n",$3,mask[1]); }; if ($1 ~ /#/ && $2 ~ /^[tTuU]/ ){ for( i=2; i<=NF; i++){ printf("%s ",$i); } printf "\n"; }}' /etc/openvpn/ccd/${1} | while read x ;
                do if [[ "$x" =~ (^[[:digit:]]+) ]] ; then ip=("${ip[@]}" "$x"); fi ;
                if [[ "$x" =~ (tcp:|udp:) ]]  ; then
                        for i in ${ip[@]} ; do
                                for j in $x ; do
#                                       port=${j#*:};
#                                       for z in $( echo $port | egrep -o '([[:digit:]]+(\,|:|$)){1,15}' ) ; do
                                        for z in $( echo ${j#*:} | $AWK 'BEGIN{FS=","; count=15; } { for(i=1;i<=NF;i++){ if ( $i ~ /:/ ) count-- ;  if ( count <= 0 ){ printf "\n"; count=15; } else if ( count != 15 ){ printf ","; } printf("%s",$i); count--; if ( $i == NF ) printf "\n" } }' ); do
                                                $iptable -A ${1} -m multiport -p ${j%%:*} -d $i --dports $z -j ACCEPT || echo "Fail -A ${1} #1";
                                        done
                                done ;
                        done;
                        unset ip ;
                fi ;
        done
        $iptable -A "${1}" -j REJECT --reject-with icmp-port-unreachable || echo "Fail -A ${1} #2"
#        line="`$iptable -nL openvpn --line | $AWK '/REJECT/{print $1}'`"
}


if [[ "${BASH_ARGV[@]}" =~ "init" ]] ; then INIT=1 ; else INIT=0 ; fi
ARGV=( ${BASH_ARGV[@]/init/} )
if [ "${#ARGV[@]}" -ge 1 ]; then
        for a in ${ARGV[@]} ; do
                #if [ "$a" == "init" ] ; then continue ; fi
                if [ -f /etc/openvpn/ccd/"${a}" ] ; then
                        if [ "$INIT" -eq 1 ] ; then
                                for k in `$iptable -nL openvpn --line | $AWK '/ '${a}' /{print $1}' | /usr/bin/tac` ;
                                        do [ "$k" -gt 0 ] && ( $iptable -D openvpn $k || echo "Fail -D openvpn" )
                                done
                        fi
                        cltabl $a
                else
                        echo -e "Wrong ccd name, Please check $a\n\n$0 [ccd name] [init]\n"
                        exit 1;
                fi
        done
else
        for l in `find /etc/openvpn/ccd -maxdepth 1 -a -type f`; do
                [[ "${l##*/}" =~ "DEFAULT" ]] && continue
                if [ "$INIT" -eq 1 ] ; then
                        for k in `$iptable -nL openvpn --line | $AWK '/ '${l##*/}' /{print $1}' | /usr/bin/tac` ; do
                                [ "$k" -gt 0 ] && $iptable -D openvpn $k
                        done
                fi
                cltabl ${l##*/}
        done
fi

