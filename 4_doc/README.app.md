# Ansible 应用部署文档

## 概览

本文档描述如何使用 Ansible 部署相关应用。

## 功能

实现对指定应用的部署及启停等操作。目前支持的应用封装类型为 docker 和 nginx。

## 设计

根据应用信息是否与部署环境相关，应用的信息分为两部分存放。与部署环境无关的信息放在全局应用变量文件 [vars/apps.yml](vars/apps.yml) 内，与部署环境相关的信息放在 inventory 的组变量内。

### 全局应用变量

全局应用变量文件是 [vars/apps.yml](vars/apps.yml)。全局应用变量的信息与部署环境无关。其中，每个字典元素对应一个应用，字典的键为应用名称，字典的值为此应用的所有信息。

以 Docker 封装类型的应用 `platform-service-runtime-ws` 为例：

```yaml
platform-service-runtime-ws:
  app_type: docker
  docker_image_project: platform
  docker_image_name: platform-service
  sub_directories: [ 'config', 'logs', 'tmp' ]
  config_files:
  - path: config/application.yml
  - path: config/rsa_pri_0.pem
    from_var: rsa_pri_0
  - path: config/rsa_pub_0.pem
    from_var: rsa_pub_0
  healthz:
    type: file
    file: logs/platform.log
    search_regex: is running
```

- `app_type`：指定应用封装类型为 docker

- `docker_image_project`：该应用的 Docker 镜像所属项目

- `docker_image_name`： 该应用的 Docker 镜像名称

- `sub_directories`：在部署此应用时需要 Ansible 提前创建的子目录列表，路径相对于应用主目录（`/home/{{ worker_user }}/{{ app_name }}/{{ instance_name }}/`（后面以 `{{ work_dir }}` 表示）。

- `config_files`：需要替换的变量文件列表，每个列表为一个字典，其可以设置以下键：

  - `path`（必填）：部署到目标主机的配置文件路径，相对于应用主目录 `{{ work_dir }}`。当下面所述的所有可选键都不存在时，Ansible 会通过模板文件 `{{ playbook_dir }}/app_config/{{ app_name }}/{{ path }}.j2` 生成配置文件，并部署到目标主机的 `{{ work_dir }}/{{ path }}`。

  - `versioned`（可选）：指定此文件对应的模板是否需版本化管理。某些配置文件会随着代码版本迭代而发生变化，因此也需要对配置文件的模板进行版本化管理。此时，模板文件必须为 `{{ playbook_dir }}/app_config/{{ app_name }}/{{ path }}-{{ version }}.j2`。

    例：

    ```yaml
    ...
    config_files:
    - path: config/application_custom.properties
      versioned: true
    ```
  
    
  
  - `from_var`（可选）：指定此文件内容的来源是所填变量的值。此时填入的变量必须已定义，同时不需要模板文件 `{{ playbook_dir }}/app_config/{{ app_name }}/{{ path }}.j2`。
  
    例：
  
    ```yaml
    ...
    config_files:
    - path: config/foo.cfg
      from_var: bar
    ```
    
    Ansible 会将变量 `bar` 的值写入目标主机的配置文件 `{{ work_dir }}/config/foo.cfg`。
    
  - `link_pattern`（可选）：有时候，每次编译后的配置文件名会发生变化。由于文件名的不确定性，我们的解决方案是：首先通过本地指定的模板生成固定名称的配置文件（fix.conf）并部署到应用服务器上，然后需要通过**给定的模式**查找到实际的配置文件名称（actual.conf），将 actual.conf 通过软链接的方式指向到 fix.conf。本选项的值即为给定的模式。
  
    注意：给定的模式应确保只会匹配一个目标文件，否则可能出现匹配错误文件的情况。
  
    例：
  
    ```yaml
    ...
    config_files:
    - path: www/config.js
      link_pattern: 'config-*'
    ```
  
    此配置会从模板 `{{ playbook_dir }}/app_config/{{ app_name }}/www/config.js.j2` 生成配置文件 `{{ work_dir }}/www/config.js`，然后查找 `{{ work_dir }}/www` 目录中符合模式 `config-*` 的文件，如 `{{ work_dir }}/www/config-kdjhoxch.js`，并将此文件改为指向到 `{{ work_dir }}/www/config.js` 的软链接。
  
- `healthz`：该应用健康检查相关的配置。根据类型的不同，需配置的键也不一样。

  - `type`：指定健康检查的类型，支持三种值：`http`、`tcp`、`file`。

    - `type: http`：当指定健康检查类型为 `http` 时，需要同时配置 HTTP 探活接口 URI（`interface`）、超时时间（`timeout`）、应返回的状态码（`status_code`）。

      例：

      ```yaml
      healthz:
        type: http
        interface: /monitor.html
        timeout: 60
        status_code: 200
      ```

    - `type: tcp`：当指定健康检查类型为 `tcp` 时，只需指定超时时间（`timeout`）。

    - `type: file`：当指定健康检查类型为 `file` 时，需要配置需监控的文件路径（相对于 `work_dir `）以及需探测的文本内容（正则式）。

      例：

      ```yaml
        healthz:
          type: file
          file: logs/start.log
          search_regex: Application \'keylist-service\' is running
      ```

### Inventory 的组变量

Inventory 的组变量将应用与特定的主机组进行关联，并存放应用在特定运行环境下所需的配置和相关资源。

以 inventory-POC-yongyou 的 org21 组为例，我们有 inventory 的全局组变量文件 [all.yml](inventory-POC-yongyou/group_vars/all.yml) 和 org21 组的变量文件 [org21.yml](inventory-POC-yongyou/group_vars/org21.yml)。下面列出与应用相关的变量，相关说明在 YAML 中已有注解。

#### all.yml

```yaml
# Docker
harbor: false  # 指定 Docker 是从配置的 Harbor 中下载镜像还是从 Ansible 控制机传输镜像
harbor_domain: hub.finrunchain.com
# Network - 定义机构之间连接模式，使用私网（private）还是公网（public）网络
# 配置 hosts 时会调用 org21.yml 中的 slb[conn_mode]
conn_mode: private
# Platform 相关配置
platform:
- id: pid001
  scheme: http
  host: res.ub.shufafin.com
  port: 80
  fabric_id: 22
- id: pid002
  scheme: http
  host: res.uf.shufafin.com
  port: 80
  fabric_id: 21
# RSA 密钥对，通过内容生成应用配置文件
rsa_pri_0: |
  -----BEGIN PRIVATE KEY-----
  MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDCoU4KRxLFTIlZ
  EWqVEBPvVptgysMIIUJZyHcx9jjz1srZSxN7dCMWgo6BukD1yS1LEVqQ0Tf7ksY3
  fDQ9hUIoUykT1coi8HXIJiLFUX4kb6s0nW4xPCHKxIBIlqWqEGnn14JPsSIo8HWM
  ev1lmVlCFh4iMnyh8Pl+iaJlb91sEEjvOy52ezcEElgEXa0AGqOHYl0t5d1QWAW3
  x+5qqxnFUM0Uxj0aqEg/UjktT4whKNko6gv6XMaV0Uaa8vLCXBwx8bPpqaEMur5O
  BgfHuEoj2u6fmsS/caS29ldKbUlLZA0jILsIpIja+3G5alNrz2f3tFHwiAUClSOo
  C9bskPlJAgMBAAECggEASyr/N+rxLe/8T8DxN/bIrDP3uG822cn2lTReDJa6sjnv
  h/J96L0W3Be6MBIeCo8TBh4Cq1GSXH/4O++lQWlY/rf3cmisM8hIxO8tmKV7oVjb
  d2uh5jQCHQy9Osur2b2TGW5bLqoLtmIAFCxf90A9f8+I/c4f4m9t/Fftt11318bZ
  p/pObc6FjOfG32ITxHeC1zUTdBlAJAt7XWF+VpYF9G4lR73uSBKMHcpt3oPTSyF0
  A5f/0hsiVdzxiF6EQnji/FG4kKmGtEmhfcT9fBTsi8nnxvtx1ofEKQ1qgPTlOeDI
  jJJ50PQkDxdCJdOeFFHh38FaOw8VUVVI9fj7zro+AQKBgQDrrDemygWlU3zWhQwb
  L5CP8eSRASSVEteOSTaB5NuxR+tAfwImlckvopW/I/30j6Y+9ahKgsSmk82TZjdE
  SWQZ+31XY2TOZ0qe22/CUebivH5WhRHTA5u5/GfP81wRaXInaItYG6phHKjCXDbz
  U/htu8T07XcOWvRJOdy1PulYQQKBgQDTatgDwNb+0UUMv2w9OWZ94HA1IL4LERL0
  x0AoyYf0xNecFMHpxhwSl0ThRbvag7y6IVWbDW0YR9mcZTW7q/FZUF66dgt2LJci
  rhqkpOAIZOEQX1wUYANSlT1d6zSi5JWpb0NTf0oRN4IEV7DaUtik9Hx0znWQwA7f
  UB1+oW0fCQKBgQCAELSpKOzKe0TCWchLWZyH7B2VgnZ7n6KNClHZYiDUBE3dXWcw
  yoJqJUKUfJ168TiYy+tomgj8sCKtL4Vm0S7ZQ6VIAJX953lQO9ROVy1NFrrcjzEx
  ZquP9I4BHbBxMci7i371IQuD/AvkmjGuJnpAPyH3KrdgkKJgzFWYFBi/QQKBgQCn
  bOl8r26Tha6lFcLmCVr9PIwfxro5kV/tsQ1CP7cHRAtrc5TNSTJaFqlZrRvDRKhk
  zpk4nT1UCTJwBEa1RMlw7ZDXITyabV2S/UXkNR2mCB2kFaCaEh8Pe1iJ1AZvKY7M
  C2zJ5vgFAmxYfAl2HD2tBGC7L/UymKYuewegjL4Z4QKBgFRAF7tEFd2sHw/Co435
  m/wPxk11HaOoz1NVd69ouZxWqB5w+j9RjpPdHvmEII++rW6WlTvbmruNRaamduiU
  ODmVJg5eHeXPIioflaoR4qT7L266P9aw+nEAOwPBA/zMw1uOb+KFOn6pE5RdlPGO
  fojPugzB+d/mcRKl8jIpAXYq
  -----END PRIVATE KEY-----
rsa_pub_0: |
  -----BEGIN PUBLIC KEY-----
  MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwqFOCkcSxUyJWRFqlRAT
  71abYMrDCCFCWch3MfY489bK2UsTe3QjFoKOgbpA9cktSxFakNE3+5LGN3w0PYVC
  KFMpE9XKIvB1yCYixVF+JG+rNJ1uMTwhysSASJalqhBp59eCT7EiKPB1jHr9ZZlZ
  QhYeIjJ8ofD5fomiZW/dbBBI7zsudns3BBJYBF2tABqjh2JdLeXdUFgFt8fuaqsZ
  xVDNFMY9GqhIP1I5LU+MISjZKOoL+lzGldFGmvLywlwcMfGz6amhDLq+TgYHx7hK
  I9run5rEv3GktvZXSm1JS2QNIyC7CKSI2vtxuWpTa89n97RR8IgFApUjqAvW7JD5
  SQIDAQAB
  -----END PUBLIC KEY-----
```

#### org21.yml

```yaml
# 在标准部署中 SLB 分内网 SLB 和公网 SLB，而公网 SLB 又有内部通信的 IP 地址和外部访问的 IP 地址。
# platform 应用需要根据 all.yml 中 conn_mode 的值确定 org21 与其他 org 之间的连接用地址
slb:
  inner: 10.10.101.44     # 内网 SLB 的 IP 地址
  private: 10.10.101.44   # 公网 SLB 的内部通信 IP 地址
  public: 1.1.1.1         # 公网 SLB 的外部访问 IP 地址（一般为防火墙 IP）

## App 实例信息，youxin 为应用在 org21 下的实例名称
instances:
  youxin:
    platform-hfclient-sdk-ws:
      listen_port: 8888   # 该应用监听的端口
      domain: apiserver.org{{ org_id }}.{{ fabric_domain }}  # 该应用对外提供服务的域名
      on_group: org{{ org_id }}_api   # 指定该应用部署在哪个 Ansible 组上
    platform-service-runtime-ws:
      platform_id: pid002   # 应用配置中需要指定自身的 platform_id，因此需配置此键值对
      listen_port: 4000
      domain: platform.org{{ org_id }}.{{ fabric_domain }}
      on_group: org{{ org_id }}_platform
    keylist-ws:
      listen_port: 6000
      domain: keylist.org{{ org_id }}.{{ fabric_domain }}
      on_group: org{{ org_id }}_keylist
    voucher-ws:
      listen_port: 5000
      domain: 124.126.12.69 # prod: uf.shufafin.com
      on_group: org{{ org_id }}_java
    voucher-view:
      listen_port: 8080
      domain: 124.126.12.69 # prod: uf.shufafin.com
      on_group: org{{ org_id }}_nginx
```



到此，应用的变量设计与配置已经完成。接下来让我们看下使用的 role。

### Role: app_deploy

提供了应用的启停、Docker 镜像拉取、二进制包上传和配置更新的功能。目录结构如下：

```sh
app_deploy
└── tasks
    ├── config-link.yml
    ├── config.yml
    ├── deploy.yml
    ├── main.yml
    ├── start.yml
    └── stop.yml

1 directory, 6 files
```

### Role: nginx

在原有 role 的 tasks/main.yml 添加了部署应用配置的 task，用于首次初始化部署时配置 Nginx 的 vhosts：

```yml
- name: Templating nginx's app config files
  template:
    src: app.conf.j2
    dest: "{{ nginx_home }}/conf/vhost/{{ app_name }}.conf"
    group: "{{ worker_group }}"
    owner: "{{ worker_user }}"
    backup: yes
  tags:
  - never
  - appconfig
  notify: reload nginx
```

模板文件 `templates/app.conf.j2` 如下：

```jinja2
{% if ngx_upstreams %}
{% for u in ngx_upstreams %}
upstream {{ u.name }} {
  {{ u.lb_mode }};
{% for s in groups[instances[instance_name][u.name]['on_group']] %}
  server {{ hostvars[s]['ansible_ssh_host'] }}:{{ instances[instance_name][u.name]['listen_port'] }} max_fails={{ u.max_fails }} fail_timeout={{ u.fail_timeout }};
{% endfor %}
}
{% endfor %}
{% endif %}

server {
    listen {{ listen_port }};
    server_name {{ instances[instance_name][app_name]['domain'] }};

    access_log logs/{{ ngx_log.name }}.access.log {{ ngx_log.format }};
    error_log  logs/{{ ngx_log.name }}.error.log;
{% if ngx_root %}
    root {{ ngx_root }};
{% endif %}

{% for l in ngx_locations %}
    location {{ l.modifier }} {{ l.uri }} {
        {{ l.config }}
{% if l.proxy_pass is defined and l.proxy_pass %}
        proxy_pass {{ l.proxy_pass }};
{% endif %}
{% if l.index is defined and l.index %}
        index {{ l.index }};
{% endif %}
    }
{% endfor %}
}
```

本模板中的 `ngx_*` 变量均来自 `vars/apps.yml` 中 `app_type` 为 `nginx` 的应用：

```yaml
# vars/apps.yml
...
factoring-portal:
  app_type: nginx
  config_files:
  - path: www/config/app.constants.js
  healthz:
    type: http
    interface: /index.html
    timeout: 10
    status_code: 200
  ngx_root: "{{ worker_home }}/{{ app_name }}/{{ instance_name }}/www"
  ngx_log: { name: 'factoring', format: 'main' }
  ngx_upstreams:
  - name: domestic-factoring-ws
    lb_mode: ip_hash
    max_fails: 2
    fail_timeout: 10s
  ngx_locations:
  - uri: (/app/|/content/)$
    modifier: '~'
    config: 'return 404;'
  - uri: /api
    modifier:
    config: 'if ($request_method ~ (TRACE|TRACK)$) { return 403; }'
    proxy_pass: 'http://domestic-factoring-ws'
  - uri: /
    modifier:
    config: 'if ($request_method ~ (TRACE|TRACK)$) { return 403; }'
    index: index.html
```

## 使用

### Playbook 路径

[app.yml](./app.yml)

### 命令行变量

| 变量名称      | 默认值 | 描述                                                         |
| ------------- | ------ | ------------------------------------------------------------ |
| app_name      | 无     | 【必需】应用名称，与 vars/apps.yml 变量的 key 对应。         |
| instance_name | 无     | 【必需】实例名称。                                           |
| version       | 无     | 当 tag 为 start / stop / restart 时可选，其他情况必须提供，为所部署应用的版本，即 Git 标签名。 |
| inventory     | 无     | 目标主机或组。                                               |

### Ansible Tag

| Tag 名称 | 描述                                                     |
| -------- | -------------------------------------------------------- |
| deploy   | 将应用运行所需的二进制包传到目标主机；或载入 Docker 镜像 |
| config   | 生成并传输应用的配置文件                                 |
| start    | 启动应用                                                 |
| stop     | 停止应用                                                 |
| restart  | 重启应用                                                 |

### 示例

```bash
# 完整部署并启动 keylist0.org21 上 keylist-ws 应用的 youxin 实例，版本为 v1.0.0_tag_hotfix
ansible-playbook app.yml \
  -e app_name=keylist-ws \
  -e instance_name=youxin \
  -e version=v1.0.0_tag_hotfix \
  -e inventory=keylist0.org21

# 重启 keylist0.org21 上 keylist-ws 应用的 youxin 实例
ansible-playbook app.yml \
  -e app_name=keylist-ws \
  -e instance_name=youxin \
  -e inventory=keylist0.org21 \
  -t restart
```

