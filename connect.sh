#!/bin/bash
#day=`date +%F.log`
[ -f /var/log/openvpn/connect.log ] || { umask 0177 ; touch /var/log/openvpn/connect.log ; }
echo "`date '+%F %H:%M:%S'` $common_name : $username from $trusted_ip ( $ifconfig_pool_remote_ip ) logged in" >> /var/log/openvpn/connect.log
