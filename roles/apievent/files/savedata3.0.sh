#!/bin/bash
#author by hoke
#this script is fabric savedata test

clear
echo -e "---------- 开始\033[41;37m $1 \033[0m次saveData接口测试 ----------"
sleep 1
for((i=1;i<=$1;i++));  
do   
	echo ""
	echo "---------- rc-asset ----------"
	curl -H  "Content-Type: application/json" -X POST  --data '
{"request_header":{"time_stamp":1526366850673,"sign":{"signature":"thJ1xb03t+jaPgP0sQuFfriZhfX5PqWu2qRJ3VJyoYkJgy3ADjkJCd474/cxNzdtFb9R7KpIp408zpdmQ4bWbKEUUztqfS8cINHdSjK5r5jV0K7/hbdRKoASLtKBpXsyJQQ8gwCe681InxQ2us8oQHP+wYCPmBpql58KLhPc6lA=","pub_key":"MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDNutvvb5cfGocVvb3xmB1spxrEesFRSTBQMhUldxJJJjGSHdsNxlzLRSRfr/SvdMsYCzwsHxe556gj7ruH9zTvVXKLx5Hr2Z+UkCE3FgsRm5sQ1mtrWvvfUmhvVvO4z44nBIZwBz/zqMa4ZAP2v579OA/ZjFXXMRzamroXjyXkZwIDAQAB","key_type":"rsa"},"wallet_address_signs":[{"signature":"thJ1xb03t+jaPgP0sQuFfriZhfX5PqWu2qRJ3VJyoYkJgy3ADjkJCd474/cxNzdtFb9R7KpIp408zpdmQ4bWbKEUUztqfS8cINHdSjK5r5jV0K7/hbdRKoASLtKBpXsyJQQ8gwCe681InxQ2us8oQHP+wYCPmBpql58KLhPc6lA=","pub_key":"MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDNutvvb5cfGocVvb3xmB1spxrEesFRSTBQMhUldxJJJjGSHdsNxlzLRSRfr/SvdMsYCzwsHxe556gj7ruH9zTvVXKLx5Hr2Z+UkCE3FgsRm5sQ1mtrWvvfUmhvVvO4z44nBIZwBz/zqMa4ZAP2v579OA/ZjFXXMRzamroXjyXkZwIDAQAB","key_type":"rsa"}],"participant_signs":[]},"request_data":"{\"tx_in\":[],\"tx_out\":[{\"asset_info\":{\"wallet_address\":\"ed5f71fcae3420b4509b227239865ecff3ffe8b6e8cecdd38408cd1474fea5e5\",\"track_status\":\"CreateAsset\",\"crypto_data\":\"Dl6sf6855LWvl5yTGud7IuXCzoDdtHDt7NMyqYE4KcHU3drgeOFn0pS1ryvVx9w2Cppeg6j9KXuFffZRdHYnvhhoz5e06ii4GbgGx4E1pZeJ4i9iAc5yaW79+2btEI23+5dtFrWcqpz3j2JTmtl5SO2PBxfoTXFL+quYu6n1zb5nXPvYuoK99YNoNsAlKOGn8faL+nR2wZqxAOuwQAPIp9jPYzbe9qSZ0zqudD+1/jjVe8OJ56KwnPfLaUtXAnkIWtIZ0+Uh/PzvnodfR8OLFhoAuYs04eWxcMEl5KW/JEp/ldr0f45H4b2hmWcyM6/p\",\"key_list\":[{\"key\":\"TDg9umyLLbFh0jYITnQlCDWBmmpTigA5OF95OYD2Ynry4xsPhijgjq/yZQuru4O8U64cG+wxWjGH1Bn+vY8p9VCCba9ykAeY4Bb5Ja8L9erQXEZa0dsST6EEgwjMiM67xY4g9BotXPBq0p9HVBlaTLW+bF5KUI5MuUc/ACspqhU=\",\"org_id\":\"org1\"}],\"plain_data\":\"\"}}],\"script_version\":\"1.0\",\"script_name\":\"CreateAsset\",\"attachment\":\"这是说明文件\"}"}
' http://127.0.0.1:3001/assetTradingPlatform/assetInvoke/CreateAsset
done