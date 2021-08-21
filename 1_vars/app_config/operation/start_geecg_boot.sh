
ROOT_PATH=/home/blockchain/operation
nohup /usr/java/jdk1.8.0_91/bin/java -server -Xms2048m -Xmx2048m -Xmn640m -Droot.path=$ROOT_PATH  -Djava.security.egd=file:/dev/./urandom -jar /home/blockchain/operation/jeecg-boot-module-system*.jar &
