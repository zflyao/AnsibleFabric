#!/bin/bash

### 用户定义信息 ###

# Inventory 名称
INVENTORY=
# ssh 信息
SSH_USER=
# 是否使用 yum ，Y or N
YUM=
# 是否使用 Docker Registry，Y or N
HARBOR=
# Kafka 域名
KAFKA_DOMAIN=
# 创世组织 Peer 信息
ORG1=
ORG1MSP=
ORG1DOMAIN=
# 创世组织 Orderer 信息
ORD1=
ORD1MSP=
# 通道与链码信息
CHANNEL=
CC_NAME=
CC_VERSION=
##################


RED="31m"      # Error message
GREEN="32m"    # Success message
YELLOW="33m"   # Warning message
BLUE="36m"     # Info message 

function colorEcho(){
  COLOR=$1
  echo -e "\033[${COLOR}${@:2}\033[0m"
}

function createInventory() {
  [ -z "$INVENTORY" ] && read -p "请输入 inventory 的名称（例如 DEMO-aliyun）：" INVENTORY
  if [ -z "$INVENTORY" ]; then
    colorEcho $YELLOW "inventory 名称不可为空，请重新输入"
    createInventory
  else
    : ${ANSIBLE_HOME:=$(cd $(dirname $0)/..; pwd)}
    cd $ANSIBLE_HOME
    if [ -d inventory-$INVENTORY ]; then
      colorEcho $RED "[ERROR] 已存在 $ANSIBLE_HOME/inventory-$INVENTORY 目录，请手动删除该目录后重新执行脚本"
      exit 1
    fi
    cp -rf inventory-template inventory-$INVENTORY
    sed -i ansible.cfg \
      -e "s|^inventory\s*=.*$|inventory = inventory-$INVENTORY|g" \
      -e "s|^fact_caching_connection\s*=.*$|fact_caching_connection = environment/inventory-$INVENTORY/fact_cache|g"
  fi
}

function getInfo() {
  [ -z "$SSH_USER" ] && read -p "请输入服务器 ssh 用户名 [root]：" SSH_USER
  : ${SSH_USER:=root}
  [ "${YUM,,}" != y -a "${YUM,,}" != n ] && read -p "是否使用 YUM 仓库安装软件包？[Y]/n：" YUM
  : ${YUM:=y}
  case $YUM in
    Y|y) YUM_VALUE=true  ;;
    N|n) YUM_VALUE=false ;;
    *) echo "请输入 Y 或 n"; getInfo ;;
  esac
  [ "${HARBOR,,}" != y -a "${HARBOR,,}" != n ] && read -p "是否使用 Harbor 仓库安装 Docker 镜像？[Y]/n：" HARBOR
  : ${HARBOR:=y}
  case $HARBOR in
    Y|y) HARBOR_VALUE=true  ;;
    N|n) HARBOR_VALUE=false ;;
    *) echo "请输入 Y 或 n"; getInfo ;;
  esac
  [ -z "$KAFKA_DOMAIN" ] && read -p "请输入 Kafka 域名 [finblockchain.cn]：" KAFKA_DOMAIN
  : ${KAFKA_DOMAIN:=finblockchain.cn}
  [ -z "$ORG1" ] && read -p "请输入创世 Peer 组织的名称，可包括小写英文和数字 [org1]：" ORG1
  : ${ORG1:=org1}
  [ -z "$ORG1MSP" ] && read -p "请输入创世 Peer 组织的 MSP ID [Org1MSP]：" ORG1MSP
  : ${ORG1MSP:=Org1MSP}
  [ -z "$ORG1DOMAIN" ] && read -p "请输入创世 Peer 组织的域名 [finblockchain.cn]：" ORG1DOMAIN
  : ${ORG1DOMAIN:=finblockchain.cn}
  [ -z "$ORD1" ] && read -p "请输入创世 Orderer 组织的名称，可包括小写英文和数字 [ord1]：" ORD1
  : ${ORD1:=ord1}
  [ -z "$ORD1MSP" ] && read -p "请输入创世 Orderer 组织的 MSP ID [Orderer1MSP]：" ORD1MSP
  : ${ORD1MSP:=Orderer1MSP}
  [ -z "$CHANNEL" ] && read -p "请输入要创建的通道名称：" CHANNEL
  if [ -z "$CHANNEL" ]; then
    colorEcho $YELLOW "通道名称不可为空，请重新输入"
    getInfo
  fi
  [ -z "$CC_NAME" ] && read -p "请输入要部署的链码名称：" CC_NAME
  if [ -z "$CC_NAME" ]; then
    colorEcho $YELLOW "链码名称不可为空，请重新输入"
    getInfo
  fi
  [ -z "$CC_VERSION" ] && read -p "请输入要部署的链码版本：" CC_VERSION
  if [ -z "$CC_VERSION" ]; then
    colorEcho $YELLOW "链码版本不可为空，请重新输入"
    getInfo
  fi
}

function configInventory() {
  cd $ANSIBLE_HOME/inventory-$INVENTORY
  if [ $ORG1 != org1 ]; then
    mv hosts_org1 hosts_$ORG1
    mv group_vars/org1.yml group_vars/${ORG1}.yml
  fi

  sed -i -e "s/org1/$ORG1/g" -e "s/ord1/$ORD1/g" hosts_$ORG1

  sed -i group_vars/all.yml \
    -e "s/ansible_ssh_user:.*$/ansible_ssh_user: $SSH_USER/g" \
    -e "s/yum:.*$/yum: $YUM_VALUE/g" \
    -e "s/harbor:.*$/harbor: $HARBOR_VALUE/g" \
    -e "s/ord1/$ORD1/g" \
    -e "s/org1/$ORG1/g" \
    -e "s/CHANNELNAME/$CHANNEL/g" \
    -e "s/CC_NAME/$CC_NAME/g" \
    -e "s/CC_VERSION/$CC_VERSION/g" \
    -e "s/kafka_domain:.*$/kafka_domain: $KAFKA_DOMAIN/g"

  sed -i group_vars/${ORG1}.yml \
    -e "s/org_name:.*$/org_name: $ORG1/g" \
    -e "s/org_mspid:.*$/org_mspid: $ORG1MSP/g" \
    -e "s/org_domain:.*$/org_domain: $ORG1DOMAIN/g" \
    -e "s/ord_name:.*$/ord_name: $ORD1/g" \
    -e "s/ord_mspid:.*$/ord_mspid: $ORD1MSP/g" \
    -e "s/CHANNELNAME/$CHANNEL/g"

  colorEcho $GREEN "inventory 配置完成！请继续手动修改主机地址和组变量 $ANSIBLE_HOME/inventory-$INVENTORY/"
}


### MAIN ###
createInventory
getInfo
configInventory
