#!/bin/bash

[ "$DEBUG" == 'true' ] && set -x

set -e

# prepend mysqld to arguments
COMMAND=${1:-'mysqld'}

export REP_USER=${REP_USER:-replicator}
export REP_PASS=${REP_PASS:-replicator}
export TTL=${TTL:-10}
export CONSUL_HOST=${CONSUL_HOST:-consul}
export CONSUL_PORT=${CONSUL_PORT:-8500}
export CONSUL="$CONSUL_HOST:$CONSUL_PORT"
export CLUSTER_NAME=${CLUSTER_NAME:-galera_cluster}

# contains functions.
. /app/bin/functions

# var start_new_cluster: decides if we should bootstrap or join cluster.
start_new_cluster=false

# env SERVICE_NAME is mandatory
if [[ -z ${SERVICE_NAME} ]]; then
  echo >&2 'error: SERVICE_NAME environment variable is mandatory'
  exit 1
fi

# give the registrator some time to register the container. 
sleep 3

# Save IPs to ip_addresses
ip_addresses="`./docker-entrypoint-initdb.d/discovery-tool -address=${CONSUL} -service=${SERVICE_NAME}-3306`"
echo $ip_addresses

if [ -n "$  " ]; then
    
    if [[ $ip_addresses == *","* ]]; then
        # join cluster
        echo "Join cluster and set gcomm:// to $ip_addresses"
        export CLUSTER_ADDRESS="gcomm://$ip_addresses?pc.wait_prim=no"
    else 
        # bootstrap cluster
        echo "Bootstrap service"
        start_new_cluster=true;
        export CLUSTER_ADDRESS="gcomm://";
    fi

else
    # there went something wrong because there is no service available. Make sure that consul is running.
    echo "No service is online or registered. Please make sure that consul is available and running"
    exit 1
fi

# function in /bin/functions file
configure_env 
init_confd

# logic to bootstrap or join a cluster.
if [ "$start_new_cluster" = true ] ; then
    exec /docker-entrypoint.sh "$@" --wsrep-new-cluster
else
    exec /docker-entrypoint.sh "$@"
fi