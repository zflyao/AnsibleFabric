#!/bin/bash
human_name=$1
long_id=`docker --config=/home/zabbix/ inspect $human_name|sed -n '3p'|awk -F ':' '{print $2}'|awk -F '"' '{print $2}'`
#ip=192.168.28.48
#port=2375


[ -f /home/zabbix/config.json ] && PID=`docker --config=/home/zabbix/ inspect -f '{{.State.Pid}}' $long_id` || PID=`docker inspect -f '{{.State.Pid}}' $long_id`

case $2 in
net_in)
#net in(rx_bytes) B#
rx_byte=`cat /proc/$PID/net/dev | grep eth0 |awk '{print $2}'`
echo $rx_byte
;;

net_out)
#net out(tx_bytes) B#
tx_byte=`cat /proc/$PID/net/dev | grep eth0 |awk '{print $10}'`
echo $tx_byte
;;

block_in)
#io write_bytes
write_byte=`sudo awk '/^write_bytes/ {print $2}' /proc/$PID/io`
echo $write_byte
;;

block_out)
#io read_bytes
read_byte=`sudo awk '/^read_bytes/ {print $2}' /proc/$PID/io`
echo $read_byte
;;

*)
echo "input error"
;;
esac
