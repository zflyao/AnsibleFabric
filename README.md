# Ansible playbook for Fabric 1.4.x（底层组件）

本文档描述如何部署一个由多个 Fabric 组织组成的 Fabric 网络和相关中间件组件，适用版本为 1.4.x。

## 架构说明与组件分布

1. 假定我们要部署的是用于 yongyou 项目 TEST 环境的三个 Fabric 组织，名称为 `org1`、`org21`、`org22`。

2. 在创世区块中只有 org1 一个组织。因此 org1 被称作“**创世组织**”，org21 和 org22 被称作“**入盟组织**”。

3. 需要创建的通道是 `channelyouxin`，安装的链码是 `youxin-0.1.1`。
4. Fabric 版本是 `1.4.0`。

4. 三个组织需部署的底层组件和中间件分别为：
   - org1：Kafka、Zookeeper、Orderer、Peer
   - org21：Peer、RabbitMQ、MongoDB、PostgreSQL、ApiServer、PlatformService、Keylist
   - org22：Peer、RabbitMQ、MongoDB、PostgreSQL、ApiServer、PlatformService、Keylist

## 配置资产信息

整个网络的资产名称为 `TEST-yongyou`。在 `$ANSIBLE_HOME` 目录创建 `inventory-TEST-yongyou` 目录，然后创建组织的 hosts 文件： [inventory-TEST-yongyou/hosts_org1](./inventory-TEST-yongyou/hosts_org1)、[inventory-TEST-yongyou/hosts_org21](./inventory-TEST-yongyou/hosts_org21) 和 [inventory-TEST-yongyou/hosts_org22](./inventory-TEST-yongyou/hosts_org22)（本文档后续所有文件的相对路径都是相对于 `$ANSIBLE_HOME`）。

> 注意：各组件都有一个分组，用于后续配置的自动替换，因此请勿修改主机名和组名的格式。

需注意的是，peer0.org1 主机需要作为管理节点做制作证书、创建通道等工作，因此该主机有一个额外的变量 `genesis=true`：

```ini
[org1_peer]
peer0.org1 ansible_ssh_host=10.255.2.112 genesis=true
```

## 配置组变量

组变量位于目录 [inventory-TEST-yongyou/group_vars/](./inventory-TEST-yongyou/group_vars/)。包括全局变量 [all.yml](./inventory-TEST-yongyou/group_vars/all.yml) 和 各组织的分组变量 [org1.yml](./inventory-TEST-yongyou/group_vars/org1.yml)、[org21.yml](./inventory-TEST-yongyou/group_vars/org21.yml) 和 [org22.yml](./inventory-TEST-yongyou/group_vars/org22.yml)。

- all.yml：存放所有主机共同的变量，包括：

  - 主机连接认证信息（`ansible_ssh_user`、`ansible_ssh_private_key_file`）
  - 环境与系统信息（文件目录、用户、内核、Docker 版本等）
  - Fabric 网络整体信息（Fabric 版本、排序服务类型、创世区块的组织、通道名称、加入通道的组织名、在通道上实例化的链码信息、链码实例化时的成员信息等）
  - 网络连接信息（即组织之间的组件通过 SLB 的哪个网络地址访问，用  `conn_mode` 表示，值可以是 `private` 或 `public`）
  - 平台服务的连接信息、密钥信息等

  因此，在此文件中我们需要根据本次需要部署的环境修改 `all.yml`，关键信息如下：

  ```yaml
  # Connection
  ansible_ssh_user: root
  # Fabric common
  fabric_harbor_project: hyperledger
  cc_harbor_project: fabric1.4
  cc_tag: latest
  fabric_deploy_ver: 1.4.0
  fabric_base_version: amd64-0.4.15
  fabric_thirdparty_version: amd64-0.4.15
  # 链码初始化时的成员
  default_msp: >-
    'Org1MSP.member','Org2MSP.member','Org3MSP.member','Org4MSP.member','Org5MSP.member',
    ......
  
  # Fabric Orderer & Genesis
  fabric_orderer_type: kafka
  fabric_genesis_orgs:
    ords:
    - ord1
    orgs:
    - org1
  # Fabric channels and chaincodes
  fabric_channels:
    channelyouxin:
      # 通道创世 Orderer 名称列表
      genesis_ords:
      - ord1
      # 通道创世 Peer 名称列表
      genesis_orgs:
      - org1
      # 通道应有的 Orderer 名称列表
      ords:
      - ord1
      # 通道应有的 Peer 名称列表
      orgs:
      - org1
      - org21
      - org22
      # 通道上的链码列表，每个元素是一个字典，需写明链码的名称 `name` 和版本 `version`
      chaincodes:
      - name: youxin
        version: 0.1.1

  # 平台服务连接信息与证书信息
  platform:
    youxin:
    - id: pid001
      scheme: http
      host: res.ub.shufafin.com
      port: 5001
      fabric_id: org22
    - id: pid002
      scheme: http
      host: res.uf.shufafin.com
      port: 5000
      fabric_id: org21
  rsa_pri_0: |
    ......
  rsa_pub_0: |
    ......
  ```

- *org_name*.yml：各组织各自的变量，需注意的变量有：

  - `org_name`：组织的表示名称，用于 Ansible 分组。如 host 文件名称为 hosts_org21，那么 `org_name` 就是 `org21`，对应的组变量就是本文件。

  - `org_mspname`：组织的 MSP 名称。

  - `org_mspid`：组织的 MSP ID。

  - `org_domain`：组织的主域名，用于各组件之间通过域名通信。

  - `peer_domain`：本组织 Peer 组件的域名。
  
  - `join_channels`：本组织加入的通道列表。

  - `own_orderer`：所在组织是否有 Orderer 组件，在本次部署中，org1 为 `true`，org2 为 `false`。
  
  - `ord_name`：本组织连接的 Orderer 组织的表示名称，用于 Ansible 分组。
  
  - `ord_mspname`：本组织连接的 Orderer 组织的 MSP 名称。
  
  - `ord_mspid`：本组织连接的 Orderer 组织的 MSP ID。
  
  - `orderer_domain`：本组织连接的 Orderer 组织的域名。
  
  - `slb`：组件之间通信时使用的 SLB 的 IP 地址。其中：
    
  - `instances`：应用实例相关信息。这部分信息与应用部署的配置有关，因此不在本文档介绍范畴。详细信息可以参考[应用部署文档](./README.app.md)。



## 修改 ansible.cfg

修改 [ansible.cfg](./ansible.cfg)，将 `inventory` 和 `fact_caching_connection` 的值修改为对应我们本次部署的值：

```ini
inventory = inventory-TEST-yongyou
fact_caching_connection = environment/inventory-TEST-yongyou/fact_cache/
```

## 创建主机 SSH 公私钥对

首先需要为 `ansible_ssh_user` 创建 SSH 公私钥对。

执行脚本 [shell/initConnection.sh](shell/initConnection.sh)，输入 `ansible_ssh_user` 对应的密码，即可生成 SSH 公私钥对。

```bash
# shell/initConnection.sh
Inventory 名称为 TEST-yongyou
请提供 root 的密码：
```

这一对文件将保存在 [environment/inventory-TEST-yongyou/sshkey](environment/inventory-TEST-yongyou/sshkey) 目录。

如果后续新增主机，比如增加了一个新的组织 `org23`，此时已经存在了 SSH 公私钥对，我们只需分发公钥到新增的主机。那么可以用 tag `deploy` 运行 Playbook `R0_SSHkey.yml`：

```bash
ansible-playbook -e inventory='org23_unique' -e ansible_ssh_pass=123456 -t deploy R0_SSHkey.yml
```



## 主机初始化

### Playbook 文件

R1_Init.yml

### 用途

设置系统的组和用户、安装所需的软件包、执行环境初始化脚本。

本地文件目录（`{{ playbook_dir }}/summary_files/common`）需至少包含以下文件和目录：

```console
summary_files/common/
└── basesoft
    ├── rsync-3.0.9-18.el7.x86_64.rpm
    ├── telnet-0.17-64.el7.x86_64.rpm
    └── net-tools-2.0-0.22.20131004git.el7.x86_64.rpm
```

> 注意：可能因为依赖问题，还需要其他底层依赖的 RPM 包。

### 示例

```bash
ansible-playbook R1_Init.yml -e inventory='*_unique'
```

### 可传入变量

| 变量名     | 默认值            | 说明                     |
| ---------- | ----------------- | ------------------------ |
| inventory  | `*_unique`          | inventory 的组名或主机 |



## 安装 Docker

### Playbook 文件

M1.1_Docker.yml

### 用途

在所需的主机上安装 Docker。安装方式取决于组变量 `yum` 的值。如果 `yum` 为 `true`，则通过 yum 安装；否则通过本地上传 RPM 包来安装。

若使用 RPM 包安装，本地文件目录（`{{ playbook_dir }}/summary_files/docker`）需包含以下两个文件：

```console
summary_files/docker
├── docker-ce-17.06-centos.tgz
└── docker-compose
```

### 示例

```bash
ansible-playbook M1.1_Docker.yml -e inventory='*_unique'
```

### 可传入变量

| 变量名         | 默认值                  | 说明                                              |
| -------------- | ----------------------- | ------------------------------------------------- |
| `inventory`      | `*_unique`                | inventory 的组名或主机名                          |
| `centosrepo` | `mirror.centos.org` | 只在 `yum` 为 `true`，且目标主机现有仓库中找不到对应 Docker 版本的包时有效，用于生成 docker-ce.repo 文件。 |



## 安装 JDK

### Playbook 文件

M1.2_JDK.yml

### 用途

在需要运行 Java 程序的主机上安装 JDK。

### 示例

```bash
ansible-playbook M1.2_JDK.yml -e inventory='*_java'
```

### 传入变量说明

| 变量名    | 默认值     | 说明                     |
| --------- | ---------- | ------------------------ |
| `inventory` | `*_unique` | inventory 的组名或主机名 |



## 安装 zookeeper

### Playbook 文件

M2_Zookeeper.yml

### 用途

安装 Zookeeper

### 示例

```bash
ansible-playbook M2_Zookeeper.yml
```

### 可传入变量

| 变量名    | 默认值 | 说明                               |
| --------- | ------ | ---------------------------------- |
| inventory | zookeeper | inventory 的组名或主机名 |



## 安装 Kafka

### Playbook 文件

M3_Kafka.yml

### 用途

安装 Kafka。如首次安装，需创建证书文件。

**注意**：制作证书需要用到 JRE 中的 `keytool` 命令，因此请确保 Ansible 控制机上已安装 JRE 或 JDK，且可以运行命令 keytool：

```sh
$ which keytool
/usr/bin/keytool
```

如尚未安装，可以使用步骤 [安装 JDK](#安装 JDK) 中的 Playbook 在 Ansible 控制机进行 JDK 的安装。

生成的文件位于目录 [environment/inventory-TEST-yongyou/kafka/](environment/inventory-TEST-yongyou/kafka/)，文件名为 `kafkaTLSserver-{{ kafka_domain |default('kafka') }}.tar.gz` 和 `kafkaTLSclient-{{ kafka_domain |default('kafka') }}.tar.gz`。其中变量 `kafka_domain` 需在全局变量文件 [inventory-TEST-yongyou/group_vars/all.yml]() 中设置，如：

```yaml
kafka_domain: finrunchain.com
```

### 示例

```bash
# 只创建证书
ansible-playbook -t cert M3_Kafka.yml
# 已有证书，直接部署并启动 Kafka
ansible-playbook M3_Kafka.yml
# 一条命令运行前两个步骤
ansible-playbook -t cert,all M3_Kafka.yml
```

### 传入变量说明

| 变量名    | 默认值 | 说明                               |
| --------- | ------ | ---------------------------------- |
| inventory | kafka | inventory 的组名或主机名 |
| kafka_domain | finrunchain.com | 服务端证书的 *CN* |

> 后续步骤必须各机构依序执行



## 安装各组织的 fabric-tools 容器

### Playbook 文件

M4.3_FabricCli.yml

### 用途

安装、启动对应每一个 Peer 的 fabric-tools 容器。

### 示例

```bash
ansible-playbook M4.3_FabricCli.yml -e inventory='org1_peer'
```

### 传入变量说明

| 变量名    | 默认值   | 说明                     |
| --------- | -------- | ------------------------ |
| inventory | `*_peer` | inventory 的组名或主机名 |



## 制作组织的 MSP 证书

### Playbook 文件

C0.1-GenerateCert.yml

### 用途

提供变量 `org` 以生成指定组织名称的 MSP 证书目录和文件。

### 示例

```bash
ansible-playbook -e org='org1' C0.1-GenerateCert.yml
```

### 可传入变量

| 变量名 | 默认值 | 说明                                                |
| ------ | ------ | --------------------------------------------------- |
| org    | 无     | 【必需】需生成组织的名称，也就是该组织的 `org_name` |



## 制作创世组织的 Keylist 证书对（账本 3.0）

### Playbook 文件

 C0.2-GenerateKeylist.yml

### 用途

在 Ansible 控制机生成账本 3.0 的链码运行时要求的组织证书对，放在 `environment/inventory-TEST-yongyou/crypto-config/peerOrganizations/{{ org }}.finblockchain.cn/crypto` 目录。

### 示例

```bash
ansible-playbook -e org=org1 C0.2-GenerateKeylist.yml
```

### 可传入变量

| 变量名 | 默认值 | 说明                                                |
| ------ | ------ | --------------------------------------------------- |
| org    | 无     | 【必需】需生成组织的名称，也就是该组织的 `org_name` |



## 上传证书到目标服务器

### Playbook 文件

C0.3-UploadCert.yml

### 用途

上传上一步生成的证书到各节点。

### 示例

```bash
ansible-playbook C0.3-UploadCert.yml
```

### 可传入变量

| 变量名    | 默认值             | 说明                     |
| --------- | ------------------ | ------------------------ |
| inventory | `*_peer:*_orderer` | inventory 的组名或主机名 |



## 生成创世区块、应用通道的 tx 文件和锚点升级 tx 文件

 ### Playbook 文件

C1-GenerateArtifacts.yml

### 用途

生成创世区块、应用通道和锚点升级的 tx 文件。

首先需确认已配置了全局变量 `fabric_channels`。参见 [inventory-TEST-yongyou/group_vars/all.yml](inventory-TEST-yongyou/group_vars/all.yml)。其中：

-  `channelyouxin` 是我们需要生成的应用通道名称；
   -  `genesis_orgs` 是该应用通道第一个配置区块中的组织，必须是 `fabric_genesis_orgs.orgs` 的子集；
   -  `orgs` 则是我们期望加入的所有组织，其中第一个组织**必须**是该通道的 `genesis_orgs` 之一；
   -  `chaincodes` 则说明了该通道上实例化了的链码信息，包括名称（`name`）、版本（`version`）、实例化策略（`policy`），策略（`policy`）如省略则使用 `OR (default_msp)`。

```yml
fabric_channels:
  channelyouxin:
    genesis_orgs:
    - org1
    orgs:
    - org1
    - org21
    - org22
    chaincodes:
    - name: youxin
      version: 0.1.1
```

### 示例

```bash
# 只生成创世系统配置区块
ansible-playbook -e org=org1 -t genesis C1-GenerateArtifacts.yml
# 只生成应用通道的 tx 文件
ansible-playbook -e org=org1 -t channel C1-GenerateArtifacts.yml
# 只生成锚点升级 tx 文件
ansible-playbook -e org=org1 -t anchor C1-GenerateArtifacts.yml
# 当然可以一个命令同时生成所有文件
ansible-playbook -e org=org1 C1-GenerateArtifacts.yml
# 命令行传入变量 channel，覆盖 fabric_channels 变量（不建议使用）
ansible-playbook -e org=org1 -e channel=channelfactor -t channel C1-GenerateArtifacts.yml
```

### 可传入变量

| 变量名  | 默认值 | 说明                                                         |
| ------- | ------ | ------------------------------------------------------------ |
| org     | 无     | 【必需】需要在哪个组织的 peer0 节点执行                      |
| channel | 无     | 指定需要生成的 channel 名称，会覆盖 `fabric_channels` 变量，应与 Tag  `channel` 同时使用 |



## 安装 Orderer

### Playbook 文件

M4.1_Orderer.yml

### 用途

安装 Orderer。

### 示例

```bash
ansible-playbook M4.1_Orderer.yml -e inventory=ord1_orderer
```

### 可传入变量

| 变量名    | 默认值      | 说明                     |
| --------- | ----------- | ------------------------ |
| inventory | `*_orderer` | inventory 的组名或主机名 |



## 安装 Peer

### Playbook 文件

M4.2_Peer.yml

### 用途

安装 Peer。

### 示例

```bash
ansible-playbook M4.2_Peer.yml -e inventory=org1_peer
```

### 可传入变量

| 变量名    | 默认值   | 说明                     |
| --------- | -------- | ------------------------ |
| inventory | `*_peer` | inventory 的组名或主机名 |



## 创建应用通道

### Playbook 文件

C2-CreateChannel.yml

### 用途

在指定组织的 peer0 节点创建变量 `fabric_channels` 中的应用通道。只有在 `fabric_genesis_orgs.orgs` 中的组织才有权限创建应用通道。

请通过命令行变量 `org` 指定组织的名称。

### 示例

```bash
ansible-playbook -e org=org1 C2.1-CreateChannel.yml
```



## 更新锚节点配置（可选）

### Playbook 文件

C2.2-UpdateAnchor.yml

### 用途

在创世组织的 peer0 节点更新指定组织在所加入的通道上的锚节点配置。

### 示例

```shell
ansible-playbook -e org=org1 C2.2-UpdateAnchor.yml
```



## 将创世组织的 Peer 加入所有应用通道

### Playbook 文件

C4-JoinChannel.yml

### 用途

此 Playbook 用于将 Peer 加入指定通道。此阶段需要将创世组织的所有 Peer 加入所有的通道。

主机需有变量 `join_channels`，值为通道名组成的列表，例如：

```yml
join_channels:
- channelyouxin
```

此变量为组织级变量，请参考变量文件 [inventory-TEST-yongyou/group_vars/org1.yml](inventory-TEST-yongyou/group_vars/org1.yml)。

### 示例

```bash
ansible-playbook C4-JoinChannel.yml -e inventory=
```

### 可传入变量

| 变量名    | 默认值 | 说明                                               |
| --------- | ------ | -------------------------------------------------- |
| inventory | 无     | 【必需】inventory 的组名或主机名                   |
| channel   | 无     | 如果需要通过命令行指定加入的通道名称，可传入此变量 |



## 在创世组织的 Peer 上安装链码

### Playbook 文件

C5.1-InstallChaincode.yml

### 用途

用于在指定的 Peer 上安装对应的链码。

### 示例

```bash
ansible-playbook -e inventory='org1_peer' C5.1-InstallChaincode.yml
```

### 可传入变量

| 变量名    | 默认值 | 说明                             |
| --------- | ------ | -------------------------------- |
| inventory | 无     | 【必需】inventory 的组名或主机名 |



## 在指定的通道上实例化链码

### Playbook 文件

C5.2-InstantiateChaincode.yml

### 用途

用于在指定的通道上实例化链码。需要目标主机存在变量 `join_channels`。

### 示例

```bash
ansible-playbook -e inventory=peer0.org1 C5.2-InstantiateChaincode.yml
```

### 可传入变量

| 变量名    | 默认值 | 说明                       |
| --------- | ------ | -------------------------- |
| inventory | 无     | 【必需】执行实例化的主机名 |



## 刷新 Keylist（账本 3.0）

### Playbook 文件

C5.3-GetKeys.yml

### 用途

用于账本 3.0 的链码刷新 Keylist。需注意对应的链码变量（[vars/chaincode.yml](vars/chaincode.yml)）的 `getKeys` 应为 True。

### 示例

```bash
ansible-playbook -e org=org1 C5.3-GetKeys.yml
```

### 可传入变量

| 变量名 | 默认值 | 说明                                    |
| ------ | ------ | --------------------------------------- |
| org    | 无     | 【必需】需要在哪个组织的 peer0 节点执行 |



## 制作入盟组织的 MSP

### Playbook 文件

C0.1-GenerateCert.yml

### 用途

通过命令行变量 `org` 指定需要制作的入盟组织名称，用于生成入盟组织的 MSP 证书目录和文件。

### 示例

```bash
ansible-playbook -e org=org21 C0.1-GenerateCert.yml
```

### 可传入变量

| 变量名 | 默认值 | 说明                                                         |
| ------ | ------ | ------------------------------------------------------------ |
| org    | org1   | 【必需】需生成组织的名称，也就是该组织的组名。由于是入盟组织所用，所以必须通过命令行传入此变量。 |



## 制作入盟组织的 Keylist 证书对（账本 3.0）

参考[制作创世组织的 Keylist 证书对（账本 3.0）](#制作创世组织的 Keylist 证书对（账本 3.0）)。



## 修改通道配置，添加入盟组织 Peer MSP

### Playbook 文件

C3.1-MembershipPeer.yml

### 用途

用于生成通道配置中入盟组织的 Peer 配置，并修改指定通道的配置。

需通过命令行指定入盟组织的名称 `add_org` 和通道的名称 `channel`。

### 示例

```bash
ansible-playbook C3.1-MembershipPeer.yml -e addorg=org21 -e channel=channelyouxin
```

### 传入变量说明

| 变量名  | 默认值 | 说明                   |
| ------- | ------ | ---------------------- |
| addorg  | 无     | 【必需】入盟组织的名称 |
| channel | 无     | 【必需】指定的通道名称 |



## 修改通道配置，添加入盟组织 Orderer MSP（可选）

### Playbook 文件

C3.2-MembershipOrderer.yml

### 用途

对于有 Orderer 的入盟组织，需要将 Orderer MSP 添加到通道中。

需通过命令行指定入盟组织的 Orderer 名称 `addord` 和通道的名称 `channel`。

### 示例

```bash
ansible-playbook C3.2-MembershipOrderer.yml -e addord=ord21 -e channel=channelyouxin
```

### 传入变量说明

| 变量名  | 默认值 | 说明                                                |
| ------- | ------ | --------------------------------------------------- |
| addord  | 无     | 【必需】入盟组织的 Orderer 名称（注意不是组织名称） |
| channel | 无     | 【必需】指定的通道名称                              |

## 安装入盟的 Peer

### Playbook 文件

M4.2_Peer.yml

### 用途

安装入盟机构的 Peer。

### 示例

```bash
ansible-playbook -e inventory=org21_peer M4.2_Peer.yml
```



## 入盟 Peer 加入通道

### Playbook 文件

 C4-Joinchannel.yml

### 用途

将入盟的 Peer 加入通道。

### 示例

```bash
ansible-playbook -e inventory=org21_peer C4-Joinchannel.yml
```



## 入盟 Peer 安装链码

参考[在创世组织的 Peer 上安装链码](#在创世组织的 Peer 上安装链码)。



## 安装 RabbitMQ

### Playbook 文件

M5_RabbitMQ.yml

### 用途

用于安装 RabbitMQ 到对应组织，需提供组织的 RabbitMQ 主机组的名称给 `inventory` 变量。

### 示例

```bash
ansible-playbook M5_RabbitMQ.yml -e inventory=org22_rabbitmq
```



## 安装 apiserver

### Playbook 文件

M4.3_API.yml

### 用途

用于安装 apiserver（SDK）。

需在组织的 `fabric_channels.channelxxx.api` 变量中配置应用的相关信息：

```yaml
    api:
      listen_port: 5555
      domain: apiserver.{{ org_domain }}
      channel: channelfft
      chaincode: fft
      rabbitmq_exchange: channelfft
      rabbitmq_group: rabbitmq
```

需在应用配置（[1_vars/common.yml]中有 api 应用的配置信息：

```yaml
HFApi:
  description: Fabric SDK (2021-7-16 Fri)
  app_type: docker
  docker_image_project: fabric1.4
  docker_image_name: runchainapi
  image_latest_tag: ws-1.2.2.005.RELEASE
  sub_directories: [ 'config', 'scripts', 'logs' ]
  config_files:
  - path: current.info
  - path: config/application-localmsp.yml
    versioned: true
  - path: config/application.yml
  - path: config/logback-spring.xml
  - path: scripts/data.txt
  - path: scripts/query.sh
    executable: true
  - path: scripts/savedata.sh
    executable: true
  - path: scripts/healthz.sh
    executable: true
  healthz:
    type: file
    file: logs/logFile.log
    search_regex: is running

# RabbitMQ
rabbitmq_port: 5672
rabbitmq_address: "{{ groups[api_vars.rabbitmq_group] | map('regex_replace','(mq\\d+).*$','\\1' ~ ':' ~ rabbitmq_port) | join(',') }}"
rabbitmq_user: loc
rabbitmq_pass: loc
```

需要以下文件：

- Docker 镜像文件（变量 `harbor` 为 `false` 时需要）：`summary_files/docker-images/runchainapi-{{ version }}.tar`

- 应用配置：

  ```tree
  app_config/platform-hfclient-sdk-ws
  ├── config
  │   ├── application-localmsp.yml-{{ version }}.j2
  │   ├── application.yml.j2
  │   └── logback-spring.xml.j2
  ├── current.info.j2
  ├── docker-compose.yml.j2
  └── scripts
      ├── data.txt.j2
      ├── healthz.sh.j2
      ├── query.sh.j2
      └── savedata.sh.j2
  ```

### 示例

```bash
ansible-playbook M4.3_API.yml -e inventory=org21_api
```

## 安装 supervisor

### Playbook 文件

M10_Supervisor.yml

### 示例

```bash
ansible-playbook M10_Supervisor.yml -e inventory=org21_java:org21_platform:org21_keylist
```



## 安装 Nginx

### Playbook 文件

M7_Nginx.yml

### 示例

```bash
ansible-playbook M7_Nginx.yml -e inventory=org21_nginx -e nginx_http=8080
```



## 安装 MongoDB

```bash
ansible-playbook -i inventory/private-POC-yongyou  M9_Mongodb.yml -e "org=21 org_id=21 architect=replica fabric_domain=finblockchain.cn"
```



## 安装 PostgreSQL

```bash
ansible-playbook -i inventory/private-POC-yongyou M12_PostgreSQL.yml -e "org=21 org_id=21 fabric_domain=finblockchain.cn"
```

​	
