# For raft
#echo "Welc@me1" | 2_shell/initConnection.sh 
# 1、初始化
#ansible-playbook R1_Init.yml -e inventory='org1_unique'
#ansible-playbook R1_Init.yml -e inventory='org2_unique'


# 2、docker和docker-compose，java克隆机器已经安装好
#ansible-playbook M1.1_Docker.yml -e inventory='*_unique'
#ansible-playbook M1.2_JDK.yml -e inventory='*_java'
#ansible-playbook M4.0_FabricCli.yml -e inventory='org*_peer'
# 制作组织的 MSP
#ansible-playbook -e org='org1' C0.1-GenerateCert.yml
#ansible-playbook -e org='org2' C0.1-GenerateCert.yml
# 制作组织的 Keylist 证书对（账本 3.0）
#ansible-playbook -e org=org1 C0.2-GenerateKeylist.yml
#ansible-playbook -e org=org2 C0.2-GenerateKeylist.yml
# 上传证书到目标服务器，默认 `*_peer:*_orderer`
#ansible-playbook C0.3-UploadCert.yml
# 修改了锚节点数据 roles/fabric_cli/templates/generate/configtx_1.4.9sm.yaml.j2
# 生成创世区块、应用通道的 tx 文件和锚点升级 tx 文件
#ansible-playbook -e org=org1 C1-GenerateArtifacts.yml
# 安装 Orderer，默认`*_orderer`
#ansible-playbook M4.1_Orderer.yml -e inventory=ord1_orderer
# 安装peer，默认`*_peer` 
#ansible-playbook M4.2_Peer.yml -e inventory=org1_peer
# 创建应用通道，在指定组织的 peer0 节点创建。
#ansible-playbook -e org=org1 C2.1-CreateChannel.yml
# 更新锚节点
#ansible-playbook -e org=org1 C2.2-UpdateAnchor.yml
# 将创世组织的 Peer 加入所有应用通道
#ansible-playbook C4-JoinChannel.yml -e inventory=org1_peer
# 在创世组织的 Peer 上安装链码
#ansible-playbook -e inventory='org1_peer' C5.1-InstallChaincode.yml
# 在指定的通道上实例化链码
#ansible-playbook -e inventory=peer0.org1 C5.2-InstantiateChaincode.yml
# 刷新 Keylist（账本 3.0） 非国密可省去这一步
#ansible-playbook -e org=org1 C5.3-GetKeys.yml
# 修改通道配置，添加入盟组织 Peer MSP
#ansible-playbook C3.1-MembershipPeer.yml -e addorg=org2 -e channel=channelsupplychain
# 安装入盟的 Peer
#ansible-playbook M4.2_Peer.yml -e inventory=org2_peer
# 入盟 Peer 加入通道 
#ansible-playbook C4-JoinChannel.yml -e inventory=org2_peer
# 组织的 Peer 上安装链码
#ansible-playbook -e inventory='org2_peer' C5.1-InstallChaincode.yml
ansible-playbook M5_RabbitMQ.yml -e inventory=rabbitmq
ansible-playbook -e inventory=org2_api M4.3_API.yml
