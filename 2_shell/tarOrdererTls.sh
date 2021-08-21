#!/bin/bash

INVENTORY=TEST-haiyun
ORDERER_DOMAIN=ord.jlhyfzf.xmeport.cn
ANSIBLE_HOME=$(cd $(dirname $0)/..;pwd)
TAR_FILE=dyck-orderer-tls.tar.gz

function tarOrdererTls () {
  cd $ANSIBLE_HOME/environment/inventory-$INVENTORY/
  tar zvcf $TAR_FILE crypto-config/ordererOrganizations/$ORDERER_DOMAIN/orderers/*/tls
  mv $TAR_FILE $ANSIBLE_HOME/shell/
}

tarOrdererTls
