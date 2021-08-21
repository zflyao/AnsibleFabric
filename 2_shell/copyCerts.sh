#!/bin/bash

ANSIBLE_HOME=$(cd $(dirname $0)/..;pwd)
INVENTORY=TEST-haiyun
MEMBERSHIP=$1

MEMBERS=(
  bocxm.com #中行
  xmbcm.bcm.com #交行
)

function copycerts() {
  local member=$1
  cd $ANSIBLE_HOME/shell
  if [ ! -f "certs-$member.tar.gz" ]; then
    echo "[ERROR] 脚本所在目录下未找到证书压缩包 certs-$member.tar.gz！"
    exit
  else
    tar zxf certs-$member.tar.gz
    if [ -d certs/peerOrganizations ]; then
      mv certs/peerOrganizations/* $ANSIBLE_HOME/environment/inventory-$INVENTORY/crypto-config/peerOrganizations/
    fi
    if [ -d certs/ordererOrganizations ]; then
      mv certs/ordererOrganizations/* $ANSIBLE_HOME/environment/inventory-$INVENTORY/crypto-config/ordererOrganizations/
    fi
    echo "[OK] $member 证书复制完成"
    rm -rf certs
  fi
}

### Main

if [ -n "$MEMBERSHIP" ]; then
  copycerts $MEMBERSHIP
else
  echo "请提供待加入组织的根域名，格式："
  echo "$0 domain"
  echo "对应组织的域名请与相关组织确认"
fi
