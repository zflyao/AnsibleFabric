#!/bin/bash +x
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

#set -e
yaml=$1
: ${yaml:="crypto-config-org{{org_id}}.yaml"}
export FABRIC_ROOT=$PWD

echo

OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')

## Generates Org certs using cryptogen tool
function generateCerts (){
	CRYPTOGEN=$FABRIC_ROOT/cryptotool/$OS_ARCH/bin/cryptogen

	if [ -f "$CRYPTOGEN" ]; then
            echo "正在使用 cryptogen -> $CRYPTOGEN"
	else
	    echo "miss cryptogen"
        exit 1
	fi

	echo
	echo "##########################################################"
	echo "##### Generate certificates using cryptogen tool #########"
	echo "##########################################################"
	$CRYPTOGEN generate --config=./$yaml
	echo
}

generateCerts