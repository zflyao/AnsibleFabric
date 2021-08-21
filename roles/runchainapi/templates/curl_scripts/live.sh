#!/bin/bash
# author by hoke
# {{ ccname |default('fft') }}探活脚本

clear
echo -e "\e[1;32m+----------------- channel{{ ccname }} {{ api_port }} 探活结果 ------------------+"
{% if chaincodeledgerversion == "1.0.3" %}
curl -I http://127.0.0.1:{{ api_port }}/factor/keepaliveQuery
{% else %}
curl http://127.0.0.1:{{ api_port }}/assetTradingPlatform/assetQuery/QueryAllOrgInfos
{% endif %}
echo
echo -e "+------------------------- \033[41;37m探活结束\033[0m\e[1;32m ----------------------------+\033[0m"