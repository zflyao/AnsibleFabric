#!/bin/bash

CHANNEL=$1
CCNAME=$2

res=`peer chaincode query -C $CHANNEL -n $CCNAME -c '{"Args":["getKey"]}' | sed "s/[][]//g"`
args={\"Args\":[\"putKey\",$res]}
peer chaincode invoke -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA -C $CHANNEL -n $CCNAME -c "$args"

sleep 3

# Verify if it successed

peer chaincode query -C $CHANNEL -n $CCNAME -c '{"Args":["getKeys"]}'
