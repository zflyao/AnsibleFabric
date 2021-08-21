#/bin/bash
PLATFORM_IP={{ ansible_ssh_host }}
PLATFORM_PORT={{ api_port }}

echo "==================================================================="
echo "Add Org1 to Blockchain"
curl -i -X POST http://$PLATFORM_IP:$PLATFORM_PORT/assetTradingPlatform/assetInvoke/AddOrgInfos \
  -H "Content-type: application/json" \
  -H "Accept: application/json" \
  --data-binary "@org1_OrgCresteScripts.txt"

echo "==================================================================="
echo "Add Org2 to Blockchain"
curl -i -X POST http://$PLATFORM_IP:$PLATFORM_PORT/assetTradingPlatform/assetInvoke/AddOrgInfos \
  -H "Content-type: application/json" \
  -H "Accept: application/json" \
  --data-binary "@org2_OrgCresteScripts.txt"

echo "==================================================================="
echo "Init AssetType to Blockchain"
curl -i -X POST http://$PLATFORM_IP:$PLATFORM_PORT/assetTradingPlatform/assetInvoke/AddAssetTypeInfos \
  -H "Content-type: application/json" \
  -H "Accept: application/json" \
  --data-binary "@init_assettype.txt"

echo "==================================================================="
echo "Init Transaction to Blockchain"
curl -i -X POST http://$PLATFORM_IP:$PLATFORM_PORT/assetTradingPlatform/assetInvoke/AddScriptInfos \
  -H "Content-type: application/json" \
  -H "Accept: application/json" \
  --data-binary "@init_transaction.txt"

echo "==================================================================="
echo "Add Org1 user to Blockchain"
curl -i -X POST http://$PLATFORM_IP:$PLATFORM_PORT/assetTradingPlatform/assetInvoke/AddAuthorizerInfos \
  -H "Content-type: application/json" \
  -H "Accept: application/json" \
  --data-binary "@org1_AddAuthorizerScript.txt"

echo "==================================================================="
echo "Add Org2 user to Blockchain"
curl -i -X POST http://$PLATFORM_IP:$PLATFORM_PORT/assetTradingPlatform/assetInvoke/AddAuthorizerInfos \
  -H "Content-type: application/json" \
  -H "Accept: application/json" \
  --data-binary "@org2_AddAuthorizerScript.txt"
  
  
