#!/bin/sh
ssid=
psk=
addr=

get_wifi_info()
{
	while read line;do
	name=`echo $line|awk -F '=' '{print $1}'`
	value=`echo $line|awk -F '=' '{print $2}'`
	case $name in 
	"ssid")
	echo "111 "$value
	ssid=$value
	;;
	"psk")
	echo "222 "$value
	psk=$value
	;;
	*)
	;;
	esac
	done</etc/wpa_supplicant/wpa_0_8.conf
	echo "ssid "$ssid
	echo "psk "$psk
	if [ -z "$psk" ];then
    	echo "psk null"
	else
    	echo "psk" $psk
	fi
}

reconnect_wifi()
{
	echo "kill wpa_suppplicant"
	killall -9 wpa_supplicant
	echo "kill udhcpc"
	killall -9 udhcpc

	wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_0_8.conf -Dnl80211
	wpa_cli -p  /etc/run/wpa_supplicant remove_network 0
	wpa_cli -p  /etc/run/wpa_supplicant add_network
	wpa_cli -p  /etc/run/wpa_supplicant set_network 0 ssid '$ssid'
	if [ -z "$psk" ];then
		wpa_cli -p  /etc/run/wpa_supplicant set_network 0 key_mgmt NONE
	else
		wpa_cli -p  /etc/run/wpa_supplicant set_network 0 psk '$psk'
	fi
	wpa_cli -p  /etc/run/wpa_supplicant select_network 0

	udhcpc -b -i wlan0
}

while [ ! -n "$addr"  ]
do
addr=$(ifconfig wlan0 | grep "inet")
echo $addr
sleep 1

done

#首次连接成功之后，开启循环检测
while :
do
	ip_addr=$(ifconfig wlan0 | grep "inet")
	wifi_ssid=$(iwconfig wlan0 | grep "ESSID")
	echo "ip_addr"$ip_addr
	echo "wifi_ssid"$wifi_ssid
	#if [ [ -z "$ip_addr" ] -a [ -z "$wifi_ssid" ] ];then
	if [ -z "$wifi_ssid" -a -z "$ip_addr" ];then
		#网络连接异常，需要重新连接
		echo "reconnect wifi"
		get_wifi_info
		reconnect_wifi
	else
		echo "network ok"
	fi
	
	sleep 180
done

