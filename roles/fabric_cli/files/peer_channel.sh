#!/bin/bash

ACTION=$1
CHANNEL_NAME=$2

WORKING_DIR=/home/channel-artifacts

function create () {
  peer channel create -c $CHANNEL_NAME -f ./${CHANNEL_NAME}_tx.pb \
    -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA
}

function update () {
  local updatetx_file=$1
  peer channel update -c $CHANNEL_NAME -f ./$updatetx_file \
    -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA
}

function join () {
  peer channel fetch 0 ${CHANNEL_NAME}.block -c $CHANNEL_NAME -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA
  peer channel join -b ./${CHANNEL_NAME}.block
}

function fetch () {
  local block_num=$1
  local output_file=$WORKING_DIR/${CHANNEL_NAME}_${block_num}.pb
  peer channel fetch -c $CHANNEL_NAME $block_num $output_file \
    -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA
}

function checkAnchor () {
  local org_mspname=$1
  peer channel fetch config config-${CHANNEL_NAME}.pb -c $CHANNEL_NAME -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA
  configtxlator proto_decode --type common.Block --input config-${CHANNEL_NAME}.pb | jq -e \
    ".data.data[0].payload.data.config.channel_group.groups.Application.groups.${org_mspname}.values.AnchorPeers"
}

function helpInfo () {
  echo -e "Usage: $0 command <channel_name> [arg]"
  echo -e "Command list:"
  echo -e "  create -- Create channel with name <channel_name>"
  echo -e "  update -- Update config of channel <channel_name> with tx file [arg]. Here 'arg' should be a file path relative to $WORKING_DIR/"
  echo -e "  join   -- Join this peer to channel <channel_name>"
  echo -e "  fetch  -- Fetch block from <channel_name> with [arg]. Here 'arg' could be one of <newest|oldest|config|(number)>"
}

mkdir $WORKING_DIR -p
cd  $WORKING_DIR
case $ACTION in
  create|0x01)    create         ;;
  update|0x02)    update $3      ;;
  join|0x03)      join           ;;
  fetch|0x04)     fetch $3       ;;
  check|0x05)     checkAnchor $3 ;;
  *)              helpInfo       ;;
esac
