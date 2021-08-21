#!/bin/bash

# 通过命令行参数指定需要增加的用户数量，默认为1
ADD_COUNT=${1:-1}
# 指定 crypto-config 所在目录，相对于 ansible home 目录
ENV_SRC=environment/inventory-TEST-haiyun

##### prohibition modify ######
RED="31m"      # Error message
GREEN="32m"    # Success message
YELLOW="33m"   # Warning message
BLUE="36m"     # Info message 
export PATH=${PWD}/bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}

################################

function colorEcho(){
  COLOR=$1
  echo -e "\033[${COLOR}${@:2}\033[0m"
}

function check() {
  if [ ! -d crypto-config ]; then
    colorEcho ${RED} "证书目录 crypto-config 不存在。请将 crypto-config 放在脚本所在目录下！"
    exit 1
  elif [ ! -r crypto-config.yaml -o ! -w crypto-config.yaml ]; then
    colorEcho ${RED} "证书配置文件 crypto-config.yaml 不存在/不可读写。请将该文件放在脚本所在目录下，并赋予读写权限！"
    exit 1
  fi
}

function updateYaml() {
  cp -f crypto-config.yaml crypto-config.yaml-origin
  CURRENT_COUNT=$(awk '/Users/{nr[NR+1]}; NR in nr {print $2}' crypto-config.yaml)
  UPDATE_COUNT=$((CURRENT_COUNT+ADD_COUNT))
  sed -i "/Users/{n;s/Count: $CURRENT_COUNT/Count: $UPDATE_COUNT/;}" crypto-config.yaml
  if [ $? -ne 0 ]; then
    mv -f crypto-config.yaml-origin crypto-config.yaml
    colorEcho ${RED} "无法更新 crypto-config.yaml 文件，生成证书失败！"
    exit 2
  fi
}

function generateUser() {
  cryptogen extend --input=crypto-config --config=./crypto-config.yaml
  if [ $? -ne 0 ]; then
    mv -f crypto-config.yaml-origin crypto-config.yaml
    colorEcho ${RED} "ERROR: 生成证书失败！"
    exit 1
  else
    rm -f crypto-config.yaml-origin
    colorEcho ${GREEN} "INFO: 生成证书成功！"
  fi
}

function tarCerts() {
  tar -zcvf crypto-config-User${UPDATE_COUNT}.tar.gz \
    crypto-config/ordererOrganizations/ord.jlhyfzf.xmeport.cn/orderers/orderer*.ord.jlhyfzf.xmeport.cn/tls/ \
    crypto-config/peerOrganizations/org.jlhyfzf.xmeport.cn/peers/peer*.org.jlhyfzf.xmeport.cn/tls/ \
    crypto-config/peerOrganizations/org.jlhyfzf.xmeport.cn/users/User${UPDATE_COUNT}@org.jlhyfzf.xmeport.cn

}
cd $(dirname $0)/../$ENV_SRC
check
updateYaml
generateUser
tarCerts
