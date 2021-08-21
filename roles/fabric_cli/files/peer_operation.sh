#!/bin/bash

# output dir
OUTPUT_DIR=/home/artifacts/$(date +%Y%m%d)
mkdir -p $OUTPUT_DIR

get_operation () {
  echo '你要做什么操作？'
  echo '1) 获取指定通道的最新配置（json）'
  echo '2) 获取指定通道的创世配置块（pb）'
  echo '3) 获取指定通道上指定区块高度的内容（json）'
  echo '4) 获取本节点已安装的链码列表'
  echo '5) 获取指定通道上已实例化的链码列表'
  echo '6) 待定'
  read -p '输入序号：' OPERATION_ID
}

get_channel () {
  peer channel list 2>/dev/null
  JOINED_CHANNELS=($(peer channel list 2>/dev/null | grep -v 'has joined:'))
  read -p '请输入你需要操作的通道名称：' CHANNEL
  for each_c in ${JOINED_CHANNELS[@]}; do
    if [ "$CHANNEL" = $each_c ]; then
      echo "你选择的是 $CHANNEL"
      return 0
    fi
  done
  echo "你输入的通道名称不在已加入的通道列表，请重新输入"
  get_channel
}

fetch_common () {
  local block_num=$1
  peer channel fetch $block_num ${block_num}_${CHANNEL}.pb -c $CHANNEL -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA
}

fetch_config () {
  fetch_common config
  configtxlator proto_decode --type common.Block --input config_${CHANNEL}.pb | jq '.data.data[0].payload.data.config' > $OUTPUT_DIR/config_${CHANNEL}.json
}

fetch_genesis () {
  fetch_common oldest
}

fetch_num () {
  fetch_common $1
  configtxlator proto_decode --type common.Block --input $1_${CHANNEL}.pb > $OUTPUT_DIR/$1_${CHANNEL}.json
}

get_installed_chaincode () {
  peer chaincode list --installed 2>/dev/null
}

get_instantiated_chaincode () {
  peer chaincode list --instantiated -C $CHANNEL 2>/dev/null
}
# MAIN
get_operation
case $OPERATION_ID in
  1)
    get_channel
    fetch_config
  ;;
  2)
    get_channel
    fetch_genesis
  ;;
  3)
    get_channel
    read -p '请输入区块的高度：' BLOCK_NUM
    fetch_num $BLOCK_NUM
  ;;
  4)
    get_installed_chaincode
  ;;
  5)
    get_channel
    get_instantiated_chaincode
  ;;
  *)
    echo '请输入正确的序号'
    get_operation
  ;;
esac
