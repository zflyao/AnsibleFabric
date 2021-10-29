#!/bin/bash

: ${ANSIBLE_HOME:=$(cd $(dirname $0)/..; pwd)}

function getPassword() {
  read -s -p "请提供 $SSH_USER 的密码：" SSH_PASS
  echo
  
  if [ -z "$SSH_PASS" ]; then
    echo "密码不可为空，请重新输入"
    getPassword
  fi
}
   

cd $ANSIBLE_HOME
INVENTORY=$(sed -n 's/^inventory\s*=\s*0_inventory\/inventory-//p' ansible.cfg)
SSH_USER=$(awk -F'[ :]+' '/ansible_ssh_user/ {print $2}' $ANSIBLE_HOME/0_inventory/inventory-$INVENTORY/group_vars/all.yml)

echo "Inventory 名称为 $INVENTORY"
getPassword

ansible-playbook -e ansible_ssh_pass=$SSH_PASS R0_SSHkey.yml
