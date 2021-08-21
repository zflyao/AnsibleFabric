#!/bin/bash +x
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

#set -e
ccname=$2
: ${ccname:="fft"}
CHANNEL_NAME=channel${ccname}
echo $CHANNEL_NAME
export FABRIC_ROOT=$PWD
export FABRIC_CFG_PATH=$PWD
echo

OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')

## Generate orderer genesis block , channel configuration transaction and anchor peer update transactions
function generateChannelArtifacts() {
    mkdir channel-artifacts

	CONFIGTXGEN=$FABRIC_ROOT/cryptotool/$OS_ARCH/bin/configtxgen
	if [ -f "$CONFIGTXGEN" ]; then
            echo "正在使用 configtxgen -> $CONFIGTXGEN"
	else
	    echo "Building configtxgen"
	    make -C $FABRIC_ROOT release
	fi

	echo "##########################################################"
	echo "#########  Generating Orderer Genesis block ##############"
	echo "##########################################################"
	# Note: For some unknown reason (at least for now) the block file can't be
	# named orderer.genesis.block or the orderer will fail to launch!
	$CONFIGTXGEN -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block

	echo
	echo "#################################################################"
	echo "###############   生成 'channelfft.tx'   ########################"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channelfft.tx -channelID channelfft

	echo
	echo "#################################################################"
	echo "#######            channelfft 生成锚节点               ##########"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchorsfft.tx -channelID channelfft -asOrg Org1MSP

	echo
	echo "#################################################################"
	echo "##############   生成 'channelfactor.tx'   ######################"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channelfactor.tx -channelID channelfactor

	echo
	echo "#################################################################"
	echo "#######           channelfactor 生成锚节点             ##########"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchorsfactor.tx -channelID channelfactor -asOrg Org1MSP
	
	echo
	echo "#################################################################"
	echo "##############   生成 'channelportal.tx'    ###################"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channelportal.tx -channelID channelportal

	echo
	echo "#################################################################"
	echo "#######           channelportal 生成锚节点           ##########"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchorsportal.tx -channelID channelportal -asOrg Org1MSP

	echo
	echo "#################################################################"
	echo "##############   生成 'channelwarehouse.tx'    ###################"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channelwarehouse.tx -channelID channelwarehouse

	echo
	echo "#################################################################"
	echo "#######           channelwarehouse 生成锚节点           ##########"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchorswarehouse.tx -channelID channelwarehouse -asOrg Org1MSP

	echo
	echo "#################################################################"
	echo "##############   生成 'channelelc-njcb.tx'    ###################"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channelelc-njcb.tx -channelID channelelc-njcb

	echo
	echo "#################################################################"
	echo "#######           channelelc-njcb.tx 生成锚节点           ##########"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchorselc-njcb.tx -channelID channelelc-njcb -asOrg Org1MSP

	echo
	echo "#################################################################"
	echo "##############   生成 'channelgreen1.tx'    ###################"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channelgreen1.tx -channelID channelgreen1

	echo
	echo "#################################################################"
	echo "#######           channelgreen1 生成锚节点              ##########"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchorsgreen1.tx -channelID channelgreen1 -asOrg Org1MSP


	echo
	echo "#################################################################"
	echo "##############   生成 'channelrc_asset.tx'    ###################"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channelrc_asset.tx -channelID channelrc_asset

	echo
	echo "#################################################################"
	echo "#######           channelrc_asset 生成锚节点           ##########"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchorsrc_asset.tx -channelID channelrc_asset -asOrg Org1MSP

	echo
	echo "#################################################################"
	echo "##############   生成 'channelnjcb-asset.tx'   ###################"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channelnjcb-asset.tx -channelID channelnjcb-asset

	echo
	echo "#################################################################"
	echo "#######           channelnjcb-asset 生成锚节点          ##########"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchorsnjcb-asset.tx -channelID channelnjcb-asset -asOrg Org1MSP

	echo
	echo "#################################################################"
	echo "##############   生成 'channelctfu.tx'        ###################"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channelctfu.tx -channelID channelctfu

	echo
	echo "#################################################################"
	echo "#######           channelctfu 生成锚节点                ##########"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchorsctfu.tx -channelID channelctfu -asOrg Org1MSP	

}


function addchannel() {

	CONFIGTXGEN=$FABRIC_ROOT/cryptotool/$OS_ARCH/bin/configtxgen
	if [ -f "$CONFIGTXGEN" ]; then
            echo "Using configtxgen -> $CONFIGTXGEN"
	else
	    echo "Building configtxgen"
	    make -C $FABRIC_ROOT release
	fi

	echo
	echo "#################################################################"
	echo "### Generating channel configuration transaction 'channel.tx' ###"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/$CHANNEL_NAME.tx -channelID $CHANNEL_NAME

	echo
	echo "#################################################################"
	echo "#######    Generating anchor peer update for Org1MSP   ##########"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors$ccname.tx -channelID $CHANNEL_NAME -asOrg Org1MSP

}

if [ $1 -eq 1 ]; then
    generateChannelArtifacts
elif [ $1 -eq 2 ]; then
    addchannel
else
    echo "命令错误  frist   eg: ./generateArtifacts.sh 1"
    echo "命令错误  add     eg: ./generateArtifacts.sh 2 mychannel1"
    exit
fi