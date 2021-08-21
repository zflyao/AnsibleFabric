#!/bin/sh
######################脚本注释#############################
# 文件名： $0                                             #
# 功  能： Create Rabbitmq exchange or queue              #
# 作  者： hoke                                           #
# 时  间： 20181025                                       #
# 清  除： rabbitmqctl purge_queue 队列名                 #
###########################################################
mq_container=`docker ps -aq -f name=mq`
TYPE=$1
EXCHANGE=$2
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
create_exchange() {
    docker exec ${mq_container} rabbitmqctl list_exchanges | grep $EXCHANGE &>/dev/null
    if [ $? -eq 0 ]; then
        echo "Exchange '$EXCHANGE' existed."
    else
    # curl -O http://127.0.0.1:15672/cli/rabbitmqadmin && chmod +x rabbitmqadmin
        docker exec ${mq_container} rabbitmqadmin -u loc -p loc declare exchange name=$EXCHANGE type=fanout
        if [ $? -eq 0 ]; then
            echo "Creat Exchange '$EXCHANGE' successfully"
        else
            echo "Failed to creat Exchange"
            exit 1
        fi
    fi

    create_queue

    docker exec ${mq_container} rabbitmqadmin -u loc -p loc declare binding source=$EXCHANGE destination=$EXCHANGE

    docker exec ${mq_container} rabbitmqadmin -u loc -p loc list bindings
}

create_queue() {
docker exec ${mq_container} rabbitmqctl list_queues name -t 5 | grep -Ev '^{'| awk 'NR>1' | grep $EXCHANGE
    if [ $? -eq 0 ]; then
        echo "Queue '$EXCHANGE' existed."
    else
        docker exec ${mq_container} rabbitmqadmin -u loc -p loc declare queue name=$EXCHANGE
        if [ $? -eq 0 ]; then
            echo "Creat Queue '$EXCHANGE' successfully"
        else
            echo "Failed to creat Queue"
            exit 1
        fi
    fi
}

if [ $TYPE == "exchange" ]; then
    create_exchange
elif [ $TYPE == "queue" ]; then
    create_queue
else
    echo "Arguments is wrong, \$1 = exchange or queue, \$2 = name"
fi