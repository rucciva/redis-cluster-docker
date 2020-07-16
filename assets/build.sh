#!/bin/bash

DIR=${1:-"/tmp/assets"}
SUPERVISOR_DIR="/etc/supervisor/conf.d"
set -euo pipefail

mkdir -p "$SUPERVISOR_DIR"
envsubst < "$DIR/supervisord.conf.tmpl" > "$SUPERVISOR_DIR/supervisord.conf"

REDIS_CLUSTER_LAST_PORT=$(( REDIS_CLUSTER_FIRST_PORT + REDIS_CLUSTER_INSTANCES_COUNT - 1 ))
for PORT in `seq $REDIS_CLUSTER_FIRST_PORT $REDIS_CLUSTER_LAST_PORT`; do
    mkdir -p "$REDIS_CLUSTER_CONF_DIR/$PORT/"
    mkdir -p "$REDIS_CLUSTER_DATA_DIR/$PORT/"
    
    # redis instance configuration
    PORT=${PORT} envsubst < "$DIR/redis.conf.tmpl" > "$REDIS_CLUSTER_CONF_DIR/$PORT/$REDIS_CLUSTER_CONF_FILE"

    # supervisor configuration
    PORT=${PORT} envsubst < "$DIR/redis.supervisord.conf.tmpl" >> "$SUPERVISOR_DIR/supervisord.conf"
done
