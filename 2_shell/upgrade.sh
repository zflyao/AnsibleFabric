#!/bin/sh

echo "UPGRADING TO 1.1"
ansible-playbook -i inventory/rong-prd R_UpgradeToFabric1.1.yml || exit 1
sleep 5
echo "UPGRADING TO 1.2"
ansible-playbook -i inventory/rong-prd R_UpgradeToFabric1.2.yml || exit 1
sleep 5
echo "UPGRADING TO 1.3"
ansible-playbook -i inventory/rong-prd R_UpgradeToFabric1.3.yml || exit 1
sleep 5
echo "UPGRADING TO 1.4"
ansible-playbook -i inventory/rong-prd R_UpgradeToFabric1.4.yml || exit 1
