#!/bin/bash +x
#
# Copyright IBM Corp. All Rights Reserved.
#set -e

CHANNEL_NAME=$2
ORG_NAME=$3
echo $CHANNEL_NAME

function genesisBlock() {
    echo "##########################################################"
    echo "#########  Generating Orderer Genesis block ##############"
    echo "##########################################################"    

    configtxgen -configPath . -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block

}

function generateChannelArtifacts() {
    echo "#################################################################"
    echo "###############   生成 '${CHANNEL_NAME}.tx'   ########################"
    echo "#################################################################"

    configtxgen -configPath . -profile ${CHANNEL_NAME} -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}_tx.pb -channelID ${CHANNEL_NAME}
   
}

function generateAnchorArtifacts() {
    echo "#################################################################"
    echo "#######            ${CHANNEL_NAME} 生成锚节点               ##########"
    echo "#################################################################"

    configtxgen -configPath . -profile ${CHANNEL_NAME} -outputAnchorPeersUpdate ./channel-artifacts/anchor-${CHANNEL_NAME}-${ORG_NAME}_tx.pb -channelID ${CHANNEL_NAME} -asOrg ${ORG_NAME}

}

function echoHelp() {
    echo "使用方法"
    echo "$0 genesis：生成创世区块（即系统通道第一个区块）"
    echo "$0 channel <channel_name>：生成通道 <channel_name> 的首个区块 tx 文件"
    echo "$0 anchor  <channel_name> <orgname>：生成通道 <channel_name> 上组织 <orgname> 的锚节点 tx 文件"
        
}

cd /home/
mkdir -p channel-artifacts/

case $1 in
  genesis)
    genesisBlock
	;;
  channel)
    generateChannelArtifacts
	;;
  anchor)
    generateAnchorArtifacts
        ;;
  *)
    echoHelp
	;;
esac
