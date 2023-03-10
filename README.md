# openvpn-ccd-firewall
OpenVPN 透過 CCD 描述檔，簡易建立 iptables rule ，openvpn client 連入後，可以將其限制

使用前準備:
1. 請先了解 openvpn ccd 使用方式，並了解後，可以自行設立，這裡不做過多贅述 
   (主要是 openvpn ccd 是透過 ssl common name 來區分，如果有多個 ccd ，就要對應不同的 common name 的 client 證書)
2. ccd 描述檔說明
3. 
   push "route 172.1.2.0 255.255.255.0"
   # tcp:22,80,443,8080,3128,5601
   push "route 172.1.3.0 255.255.255.0"
   # tcp:22,80,443,3128
	 
   push 為原 openvpn 必要參數，會推送此 ccd 的 路由表
   緊接著 push 後的一行，格式如下
   # [tcp/udp]:port_number1,port_number2 [tcp/udp]:port_number3,port_number4
   
   

使用方式:
0. 請將所有檔案放至 /etc/openvpn

1. 請在 openvpn server config 加入下列指令
learn-address /etc/openvpn/learn-address.sh
client-connect /etc/openvpn/connect.sh
client-disconnect /etc/openvpn/disconnect.sh
script-security 2
ccd-exclusive

2. 後期因搭配 PVE (debian system) ，請直接在 /etc/modprobe.d/netfitler.conf ，加入 options xt_recent ip_list_tot=16384 ip_list_perms=0666"
   若不能修改 netfilter.conf ，請在 defaultrule.sh 18,25列，把 # remark 移除

3. OpenVPN 要執行前，請先執行 defaultrule.sh ，有幾個方法
   a. openvpn server config  , 加入
     up /etc/openvpn/defaultrule.sh
   b. /etc/rc.local

4. 如果 ccd 內的描述檔，有修改，可以單獨執行，重設 rule
   /etc/openvpn/defaultrule.sh vip init

5. 如果有問題，再請上 issue 吧
