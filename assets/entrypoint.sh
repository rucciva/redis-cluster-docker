#!/bin/bash

IP=$(eval $REDIS_CLUSTER_IP_COMMAND)

function wait_redis_instances(){
    loop=0
    until (( $loop==1 )); do
        echo "waiting..."
        sleep 3
        
        REDIS_CLUSTER_LAST_PORT=$(( REDIS_CLUSTER_FIRST_PORT + REDIS_CLUSTER_INSTANCES_COUNT - 1 ))
        for PORT in `seq $REDIS_CLUSTER_FIRST_PORT $REDIS_CLUSTER_LAST_PORT`; do
            redis-cli -h $IP -p $PORT ping 
            
            if (( $? != 0 )); then
                echo "redis at $IP:$PORT is not yet up"
            else
                echo "redis at $IP:$PORT is up"
                loop=1
            fi
        done
    done
}

function init_cluster(){
    wait_redis_instances

    CMD="echo 'yes' | redis-cli --cluster create --cluster-replicas 1"
    REDIS_CLUSTER_LAST_PORT=$(( REDIS_CLUSTER_FIRST_PORT + REDIS_CLUSTER_INSTANCES_COUNT - 1 ))
    for PORT in `seq $REDIS_CLUSTER_FIRST_PORT $REDIS_CLUSTER_LAST_PORT`; do
        CMD="$CMD $IP:$PORT"
    done
    eval $CMD    
}

function prepare_data_dir(){
    REDIS_CLUSTER_LAST_PORT=$(( REDIS_CLUSTER_FIRST_PORT + REDIS_CLUSTER_INSTANCES_COUNT - 1 ))
    for PORT in `seq $REDIS_CLUSTER_FIRST_PORT $REDIS_CLUSTER_LAST_PORT`; do
        mkdir -p "$REDIS_CLUSTER_DATA_DIR/$PORT/"
    done
}

function change_ip(){
    REDIS_CLUSTER_LAST_PORT=$(( REDIS_CLUSTER_FIRST_PORT + REDIS_CLUSTER_INSTANCES_COUNT - 1 ))
    for PORT in `seq $REDIS_CLUSTER_FIRST_PORT $REDIS_CLUSTER_LAST_PORT`; do
        conf="$REDIS_CLUSTER_DATA_DIR/$PORT/$REDIS_CLUSTER_CONF_FILE"
        regexp="[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}"
        sed -e "s/$regexp:/$IP:/g" "$conf"
    done
}

prepare_data_dir
if [ ! -f /initiated ]; then 
    init_cluster &
    touch /initiated   
else
    change_ip
fi

exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
