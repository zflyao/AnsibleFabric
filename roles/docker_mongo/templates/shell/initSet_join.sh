#!/bin/bash

CMD=/opt/mongodb/bin/mongo
MONGO_PORT=$(grep -v "#" ../docker-compose.yml | awk -F '=' '/MONGO_PORT/{print $2}')
CONTAINER_NAME=$(grep -v "#" ../docker-compose.yml | awk -F '[: ]' '/container_name/{print $NF}')
MONGO_REPLSTAT=$(grep -v "#" ../docker-compose.yml | awk -F '=' '/MONGO_REPLSTAT/{print $2}')
MONGO_ADMIN=$(grep -v "#" ../docker-compose.yml | awk -F '=' '/MONGO_ADMIN=/{print $2}')
MONGO_ADMINPASS=$(grep -v "#" ../docker-compose.yml | awk -F '=' '/MONGO_ADMINPASS=/{print $2}')

replCreate(){
docker exec -it ${CONTAINER_NAME} ${CMD} --port ${MONGO_PORT} admin  --quiet /opt/mongodb/conf/creatRepl.js
sleep 15
}

adminCreate(){
docker exec -it ${CONTAINER_NAME} ${CMD} --port ${MONGO_PORT} admin  --quiet /opt/mongodb/conf/creatAdmin.js
}


initSet() {
if [ ! -z $MONGO_REPLSTAT ]&&[ $MONGO_REPLSTAT == 'true' ];then
    replCreate
    adminCreate
else
    adminCreate

fi

}

usersCreate() {
cd jsDefault/joinorg
for jsfile in `ls create*User.js`
  do 
     cp -rf $jsfile ../../$jsfile 
     db_name=`grep db.createUser ../../$jsfile|awk -F 'db:' '{print $2}'|awk -F '"' '{print $2}'`
     sed -i "s/\<MONGO_ADMIN\>/${MONGO_ADMIN}/g" ../../$jsfile
     sed -i "s/\<MONGO_ADMINPASS\>/${MONGO_ADMINPASS}/g" ../../$jsfile
     docker cp ../../$jsfile ${CONTAINER_NAME}:/opt/mongodb/conf
     docker exec -it ${CONTAINER_NAME} ${CMD} --port ${MONGO_PORT} $db_name  --quiet /opt/mongodb/conf/$jsfile
  done
cd ../../
}


dataInit() {
docker cp dataInit_join.js ${CONTAINER_NAME}:/opt/mongodb/conf
docker exec -it ${CONTAINER_NAME} ${CMD} --port ${MONGO_PORT} mongocloud  --quiet /opt/mongodb/conf/dataInit_join.js
}

echo -e "pleasr wait, loading initial configtation......"
initSet
usersCreate
dataInit
