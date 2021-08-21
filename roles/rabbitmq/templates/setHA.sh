#!/bin/sh
######################脚本注释#############################
# 文件名： setHA.sh                                       #
# 功  能： Set Rabbitmq mirror policy                     #
# 作  者： hoke                                           #
# 时  间： 20181025                                       #
# 清  除： rabbitmqctl purge_queue 队列名                 #
###########################################################
mq_container=`docker ps -aq -f name=mq`

# Set Check shell
# policy_check=`docker exec ${mq_container} rabbitmqctl list_policies | awk 'NR>1 {print $2}'`
# 
# check_messages(){
# if [ `docker exec ${mq_container} rabbitmqctl list_queues messages | sed -n '/[1-9]/p' | wc -l` -ne 0 ]; then
#     echo "WARN: MQ 队列中有拥塞消息，请人工介入"
#     echo
#     exit 1
# fi
# }

policy_check=`docker exec ${mq_container} rabbitmqctl list_policies | grep -v name | awk 'NR>1 {print $2}'`
check_messages(){
if [ `docker exec ${mq_container} rabbitmqctl list_queues messages -t 5 | grep -Ev '^{'| awk 'NR>1' | sed -n '/[1-9]/p' | wc -l` -ne 0 ]; then
    echo "WARN: MQ 队列中有拥塞消息，请人工介入"
    echo
    exit 1
fi
}

if [ "$policy_check" = "ha-all" ]; then
    echo "WARN: RabbitMQ mirror-policy has been set [ha-all], nothing to do."
    exit 0
else
    check_messages
    docker exec ${mq_container} rabbitmqctl set_policy ha-all "^" '{"ha-mode":"all"}'
    echo "IFNO: RabbitMQ mirror-policy has been set successfully."
    exit 0
fi