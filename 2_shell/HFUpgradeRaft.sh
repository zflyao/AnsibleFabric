#! /bin/bash

CHANNELS=(testchainid channelelc-njcb channelfactor channelfft channelgangbao channelgreen1 channelnangang channelnjcb-asset channelportal channelrc-asset channelsucai channelwarehouse)
ABS_PATH="$( cd -P "$( dirname $0 )" && pwd )"
CRYPTO_PATH="/etc/hyperledger/fabric/crypto-config/ordererOrganizations"
CONSENTERS=(
orderer0.ord1.finblockchain.cn:7001
orderer1.ord1.finblockchain.cn:7002
orderer0.ord12.finblockchain.cn:7050
orderer1.ord12.finblockchain.cn:7050
orderer0.ord11.finblockchain.cn:7050
)
cd $ABS_PATH

askProceed() {
  echo "----------- $CH_NAME processing ----------------"
  read -p "Continue? [Y/n] " ans
  case "$ans" in
  y | Y | "")
    echo "$CH_NAME Starting..."
    ;;
  n | N)
    echo "Skip ${CH_NAME}, Exiting..."
    exit 0
    ;;
  *)
    echo "Invalid input!!!"
    askProceed
    ;;
  esac
}

Cap_json() {
  if [ ! -f orderer_capabilities.json ]; then
cat > orderer_capabilities.json <<EOF
{
"mod_policy": "Admins",
"value": {
    "capabilities": {
    "V1_4_2": {}
    }
},
"version": "1"
}
EOF
  fi
if [ ! -f channel_capabilities.json ]; then
cat > channel_capabilities.json <<EOF
{
  "mod_policy": "Admins",
  "value": {
    "capabilities": {
      "V1_4_3": {}
    }
  },
  "version": "2"
}
EOF
fi
if [ ! -f application_capabilities.json ]; then
cat > application_capabilities.json <<EOF
{
  "mod_policy": "Admins",
  "value": {
    "capabilities": {
      "V1_4_2": {}
    }
  },
  "version": "3"
}
EOF
fi
}

SetGlobals() {
  if [ $1 == "orderer" ]; then
    export CORE_PEER_LOCALMSPID=Orderer1MSP
    export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/ordererOrganizations/ord1.finblockchain.cn/orderers/orderer0.ord1.finblockchain.cn/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/ordererOrganizations/ord1.finblockchain.cn/users/Admin@ord1.finblockchain.cn/msp
    export CORE_PEER_ADDRESS=orderer0.ord1.finblockchain.cn:7050
  else
    export CORE_PEER_LOCALMSPID=Org1MSP
    export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.finblockchain.cn/peers/peer0.org1.finblockchain.cn/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.finblockchain.cn/users/Admin@org1.finblockchain.cn/msp
    export CORE_PEER_ADDRESS=peer0.org1.finblockchain.cn:7051
  fi
}

fetch_config() {
  if [[ $CH_NAME == "testchainid" ]] || [[ ${FUNCNAME[1]} == "Orderer" ]] || [[ ${FUNCNAME[1]} == "3_UpdateRaft" ]] || [[ ${FUNCNAME[1]} == "switch_Maintenance" ]]; then
    SetGlobals orderer
  else
    SetGlobals peer
  fi
  peer channel fetch config ${CH_NAME}_config_block.pb -o orderer0.ord1.finblockchain.cn:7050 -c $CH_NAME  --tls --cafile $ORDERER_CA
  configtxlator proto_decode --input ${CH_NAME}_config_block.pb --type common.Block --output ${CH_NAME}_config_block.json
  jq .data.data[0].payload.data.config ${CH_NAME}_config_block.json > ${CH_NAME}_config.json
}

Compute_delta() {
  configtxlator proto_encode --input ${CH_NAME}_config.json --type common.Config --output ${CH_NAME}_config.pb
  configtxlator proto_encode --input ${CH_NAME}_modified_config.json --type common.Config --output ${CH_NAME}_modified_config.pb
  configtxlator compute_update --channel_id $CH_NAME --original ${CH_NAME}_config.pb --updated ${CH_NAME}_modified_config.pb --output ${CH_NAME}_config_update.pb
  configtxlator proto_decode --input ${CH_NAME}_config_update.pb --type common.ConfigUpdate --output ${CH_NAME}_config_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CH_NAME'", "type":2}},"data":{"config_update":'$(cat ${CH_NAME}_config_update.json)'}}}' | jq . > ${CH_NAME}_config_update_in_envelope.json
  configtxlator proto_encode --input ${CH_NAME}_config_update_in_envelope.json --type common.Envelope --output ${CH_NAME}_config_update_in_envelope.pb
}

submit_update() {
  if [[ $CH_NAME != "testchainid" ]] && [[ ${FUNCNAME[1]} == "Channel" ]]; then
    SetGlobals peer
    peer channel signconfigtx -f ${CH_NAME}_config_update_in_envelope.pb
    SetGlobals orderer
  fi  
  peer channel update -f ${CH_NAME}_config_update_in_envelope.pb -c $CH_NAME -o orderer0.ord1.finblockchain.cn:7050 --tls true --cafile $ORDERER_CA
}
RestartContainer() {
  # docker restart $(docker ps -a | grep "hyperledger/fabric" | awk '{print $1}')
  echo
  echo "Restart all containers with the following command:"
  echo "docker restart `docker ps -aq`"
  echo
}
Orderer() {
  fetch_config
  jq -s '.[0] * {"channel_group":{"groups":{"Orderer": {"values": {"Capabilities": .[1]}}}}}' ${CH_NAME}_config.json ./orderer_capabilities.json > ${CH_NAME}_modified_config.json
  Compute_delta
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CH_NAME'", "type":2}},"data":{"config_update":'$(cat ${CH_NAME}_config_update.json)'}}}' | jq . > ${CH_NAME}_config_update_in_envelope.json
  submit_update
}
# peer signconfigtx
Channel() {
  fetch_config
  jq -s '.[0] * {"channel_group":{"values": {"Capabilities": .[1]}}}' ${CH_NAME}_config.json channel_capabilities.json > ${CH_NAME}_modified_config.json
  Compute_delta
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CH_NAME'", "type":2}},"data":{"config_update":'$(cat ${CH_NAME}_config_update.json)'}}}' | jq . > ${CH_NAME}_config_update_in_envelope.json
  submit_update
}

Application() {
  fetch_config
  jq -s '.[0] * {"channel_group":{"groups":{"Application": {"values": {"Capabilities": .[1]}}}}}' ${CH_NAME}_config.json application_capabilities.json > ${CH_NAME}_modified_config.json
  Compute_delta
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CH_NAME'", "type":2}},"data":{"config_update":'$(cat ${CH_NAME}_config_update.json)'}}}' | jq . > ${CH_NAME}_config_update_in_envelope.json
  submit_update
}

1_UpdateCap() {
  Cap_json
  for ((i=0;i<${#CHANNELS[@]};i++ )); do
    CH_NAME=${CHANNELS[$i]}
    # askProceed
    Orderer
    sleep 5
    Channel
    if [ $CH_NAME != "testchainid" ]; then
      sleep 5
      Application
    fi
  done  
}

switch_Maintenance() {  # $1: original_config.json (input), $2: modified_config.json (output)
  fetch_config
  if [ $1 == "maintenance" ]; then
    sed 's/NORMAL/MAINTENANCE/g' ${CH_NAME}_config.json > ${CH_NAME}_modified_config.json || exit 2
  else
    sed 's/MAINTENANCE/NORMAL/g' ${CH_NAME}_config.json > ${CH_NAME}_modified_config.json || exit 2
  fi  
  Compute_delta
  submit_update
}

2_EnableMaintenance() {
  for ((i=0;i<${#CHANNELS[@]};i++ )); do
    CH_NAME=${CHANNELS[$i]}
    # askProceed
    switch_Maintenance $1
    sleep 10
  done
  RestartContainer
}

Raft_json() {
  cat << EOF > raft.json
  {
    "ConsensusType": {
      "mod_policy": "Admins",
      "value": {
        "metadata": {
          "consenters": [],
          "options": {
            "election_tick": 10,
            "heartbeat_tick": 1,
            "max_inflight_blocks": 5,
            "snapshot_interval_size": 20971520,
            "tick_interval": "500ms"
          }
        },
        "state": "STATE_MAINTENANCE",
        "type": "etcdraft"
      },
      "version": "1"
    }
  }
EOF

 for ((i=0;i<${#CONSENTERS[@]};i++ )); do
    HOST=$(echo ${CONSENTERS[$i]} |awk -F ':' '{print $1}')
    ORDMSP=$(echo $HOST | cut -d . -f2-4)
    PORT=$(echo ${CONSENTERS[$i]} |awk -F ':' '{print $2}')
    TLS_CERT=${CRYPTO_PATH}/${ORDMSP}/orderers/${HOST}/tls/server.crt

    if [ ! -f "$TLS_CERT" ]; then
      echo "ERROR: $TLS_CERT does not exist!"
      exit
    fi

    TLS_CERT_VAL=$(base64 -w0 $TLS_CERT)
    cat << EOF > consenter.json
    {
        "client_tls_cert": "$TLS_CERT_VAL",
        "host": "$HOST",
        "port": $PORT,
        "server_tls_cert": "$TLS_CERT_VAL"
    }
EOF
    jq -s '.[0].ConsensusType.value.metadata.consenters+=[.[1]]|.[0]' raft.json consenter.json > raft_${i}.json
    [ $? ] || exit
    mv raft_${i}.json raft.json
  done
}

3_UpdateRaft() {
  Raft_json
  consensus_json_path='.[0] * {"channel_group":{"groups":{"Orderer": {"values": {"ConsensusType": .[1].ConsensusType}}}}}'
  for ((i=0;i<${#CHANNELS[@]};i++ )); do
    CH_NAME=${CHANNELS[$i]}
    # askProceed
    fetch_config
    jq -s "$consensus_json_path" ${CH_NAME}_config.json raft.json > ${CH_NAME}_modified_config.json
    Compute_delta
    submit_update
    sleep 5
  done
  RestartContainer
}

case "$1" in
  1)
    echo "Upgrade Capablities"
    1_UpdateCap
    ;;
  2)
    echo "Switch ON Maintenace mode"
    2_EnableMaintenance maintenance
    ;;
  3)
    echo "Switch ON Maintenace mode"
    3_UpdateRaft
    ;;
  4)
    echo "Switch OFF Maintenace mode"
    2_EnableMaintenance normal
    ;;      
  *)
    echo "Invalid input!!!"
    exit 0
    ;;
esac