#!/bin/bash

Continue="5min"

s_time=`date +%Y%m%d%H%M%S`
e_time=`date -d "+${Continue}"  +%Y%m%d%H%M%S`

cd api*_org1/fft/scripts/
while [ `date +%Y%m%d%H%M%S` -le ${e_time} ]
do
   bash savedata.sh >> ${s_time}-save.log
   echo >> ${s_time}-save.log
   sleep 5
done
echo ========OVER========
