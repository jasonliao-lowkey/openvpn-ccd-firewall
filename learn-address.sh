#!/bin/sh

# This is an openvpn learn-address script that modifies PF rules dynamically
# and supports 'profiles' to allow you to manage client connections without
# the headache of assigning static IPs.

# $1 is add/update/delete
# $2 is IP/Subnet/MAC
# $3 is certificate's common name
Table="openvpn"
PWD="/etc/openvpn"
GREP="/bin/grep"
AWK="/usr/bin/awk"
if [ -z "$1" ] ; then
        echo -e "$0 [add|delete|update] [src ip] [common name match with ccd file]"
        exit 1
else
        cd $PWD
        case $1 in
                "delete")
                        echo "removing $2 for any /proc/net/xt_recent/*"
                        for x in `$GREP -H "$2" /proc/net/xt_recent/* | $AWK 'BEGIN{FS=":"} {print $1}'` ; do
                                echo "-$2" > $x
                        done
                        ;;
                "add")
                        if [ ! -f ccd/$3 ]; then
                                echo "$0: No profile match for $3"
                                exit 1
                        fi
                        echo "Add $2 to /proc/net/xt_recent/$3 table"
                        echo "+$2" > /proc/net/xt_recent/$3 
                        if [ $? -ne 0 ] ; then
                                echo "add ip rule fail...";
                                exit 1;
                        fi
                        ;;
                "update")
                        echo "Update $2 to /proc/net/xt_recent/$3 table"
                        $0 delete $2
                        $0 add $2 $3
                        ;;
        esac
fi

