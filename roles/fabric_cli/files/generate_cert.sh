#!/bin/bash +x
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

#set -e
yaml=$1
: ${yaml:="crypto-config-org1.yaml"}
export FABRIC_ROOT=$PWD

echo

OUTPUT=/home/crypto-config
## Generates Org certs using cryptogen tool
function generateCerts (){

	echo
	echo "##########################################################"
	echo "##### Generate certificates using cryptogen tool #########"
	echo "##########################################################"

	cryptogen generate --config=$yaml --output=$OUTPUT
	echo
}

rm -rf $OUTPUT
generateCerts
