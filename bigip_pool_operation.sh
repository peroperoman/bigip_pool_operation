#!/bin/bash

### Args
POOL_NAME="$1"
PORT="$2"
NODE_NAME="$3"
MODE="$4"
ARGS=$#

### Function
display_usage()
{
cat <<EOF

Required settings for .env .
================================
    BIGIP_IP=""
    USER=""
    PWD=""
================================

Usage:
    $(basename ${0}) <pool> <port> <node> <mode>

Note:
    <pool> <port> <node> <mode> are must arguments.

mode:
    on  => enable node
    off => disable node

EOF
}

load_env(){
    if [ ! -s ./.env ] ; then
        display_usage
        exit 1
    else
        source ./.env
    fi
}

check_args()
{
    if [ $ARGS -eq 4 ] ; then
        return
    else
        display_usage
        exit 1
    fi
}

check_online_node(){
    count=$(curl -sk -u ${USER}:${PWD} ${common_url}/ | jq '.items[] | select(.state == "up")' | grep -w "name" | wc -l)
    if [ $count -le 1 ] ; then
        exit 1 
    fi
}

node_operation()
{
    curl -sk -u ${USER}:${PWD} -X PUT "${api_url}/~Common~${NODE_NAME}:${PORT}" -H 'Accept: */*' \
    -H 'Content-Type: application/json' -d '{ "state": "user-'$1'", "session": "user-'$2'" }'
}


### Main
load_env
check_args

# vars
common_url="https://${BIGIP_IP}/mgmt/tm/ltm/pool/~Common~${POOL_NAME}/members"
api_url="${common_url}/~Common~${NODE_NAME}:${PORT}"

case "$MODE" in
    off)
        check_online_node
        node_operation down disabled ;;
    on)
        node_operation up enabled  ;;
    *)
        usage_display
        exit 1 ;;
esac

exit 0
