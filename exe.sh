#!/bin/bash

j(){
 if [ $1 -ne 0 ];then
    echo 执行失败，退出
    exit
 fi
}

ex(){
  IFS=$'\n'
  for i in $(cat ok.sh)
  do
    echo -e "\e[1;31m$i\e[0m"
    echo "$i" | grep '#' 2> /dev/null && continue
    eval "$i"
    j $?
    echo ------------------------------------------ 执行成功---------------------------------------------
    echo
    sleep 1
  done
}
ex
