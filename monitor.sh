#!/bin/sh

expireTime=7200

dbFile="db.json"

corpid=wxa3390848e98732d5
corpsecret=71XC1TwPpJn1WYLok0GTE66cEOB99_herfpOYfD2z0c

touser="sunhaibao"
toparty="1"
agentid="1000012"
content="服务器快崩了，你还在这里吟诗作对？"

# s 为秒，m 为 分钟，h 为小时，d 为日数  
interval=1s

## 发送报警信息
sendMsg(){
    if [ ! -f "$dbFile" ];then
            touch "$dbFile"
    fi

    # 获取token
    req_time=`jq '.req_time' $dbFile`
    current_time=$(date +%s)
    refresh=false
    if [ ! -n "$req_time" ];then
            refresh=true
    else
            if [ $((current_time-req_time)) -gt $expireTime ];then
                refresh=true
            fi
    fi
    if $refresh ;then
        req_access_token_url=https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=$corpid\&corpsecret=$corpsecret
        access_res=$(curl -s -G $req_access_token_url | jq -r '.access_token')
	echo $access_res		
        ## 保存文件
        echo "" > $dbFile
        echo -e "{" > $dbFile
        echo -e "\t\"access_token\":\"$access_res\"," >> $dbFile
        echo -e "\t\"req_time\":$current_time" >> $dbFile
        echo -e "}" >> $dbFile

        echo ">>>刷新Token成功<<<"
    fi 

    ## 发送消息
    msg_body="{\"touser\":\"$touser\",\"toparty\":\"$toparty\",\"msgtype\":\"text\",\"agentid\":$agentid,\"text\":{\"content\":\"$content\"}}"
    access_token=`jq -r '.access_token' $dbFile`
    req_send_msg_url=https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=$access_token
    req_msg=$(curl -s -H "Content-Type: application/json" -X POST -d $msg_body $req_send_msg_url | jq -r '.errmsg')

    echo "触发报警发送动作，返回信息为：" $req_msg    

}


loopMonitor(){
    echo 'loop'
    flag=`uptime | awk '{printf "%.2f\n", $11 "\n"}'`


    # 0.7 这个阈值可以视情况而定，如cpu核数为n，则可以设置为0.7 * n  具体视情况而定
    c=$(echo "$flag > 1.4" | bc)

    echo ">>>>>>>>>>>>>>>>>>`date`<<<<<<<<<<<<<<<<<<"
    free -m | awk 'NR==2{printf "Memory Usage: %s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }'
    df -h | awk '$NF=="/"{printf "Disk Usage: %d/%dGB (%s)\n", $3,$2,$5}'
    uptime | awk '{printf "CPU Load: %.2f\n", $11 "\n"}'
    echo ">>>>>>>>>>>>>>>>>>end<<<<<<<<<<<<<<<<<<"

    if [ $c -eq 1  ];then
	 content="";
         sendMsg
    fi
}


while true; do
    loopMonitor
    sleep $interval
done
