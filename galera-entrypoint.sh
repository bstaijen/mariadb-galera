#!/bin/bash

[ "$DEBUG" == 'true' ] && set -x

set -e

# prepend mysqld to arguments
COMMAND=${1:-'mysqld'}

# export environment variables. if empty set default.
export REP_USER=${REP_USER:-replicator}
export REP_PASS=${REP_PASS:-replicator}
export TTL=${TTL:-10}
export CONSUL="$CONSUL_HOST:$CONSUL_PORT"
export CLUSTER_NAME=${CLUSTER_NAME:-galera_cluster}

# possibilities etcd, consul
export BACKEND=${BACKEND:-etcd}

# set defaults for consul and etcd
export CONSUL_HOST=${CONSUL_HOST:-consul}
export CONSUL_PORT=${CONSUL_PORT:-8500}
export ETCD_HOST=${ETCD_HOST:-etcd}
export ETCD_PORT=${ETCD_PORT:-4001}

# contains shell functions.
. /app/bin/functions

# start_new_cluster decides if we should bootstrap or join cluster.
start_new_cluster=false

# env SERVICE_NAME is mandatory
if [[ -z ${SERVICE_NAME} ]]; then
    echo >&2 'error: SERVICE_NAME environment variable is mandatory'
    exit 1
fi

#
ip_addresses=

# set the discovery backend (default is etcd)
if [[ $BACKEND == "consul"  ]]; then
    echo "[info] Depends CONSUL for configuration"
    # create confd configuration for consul
    configure_consul

    # trigger confd
    init_confd

    # get comma-seperated list from consul. 
    # Note: discovery-tool is a small Go program including the official consul golang api and queries for registered services.
    ip_addresses="`./docker-entrypoint-initdb.d/discovery-tool -address=${CONSUL} -service=${SERVICE_NAME}-3306`"

else
    echo "[info] Depends ETCD for configuration"
    # create etcd configuration for consul
    configure_etcd 

    # trigger confd
    init_confd

    # get cluster members from service discovery
    cluster_members

    # print comma-seperated set of IP's
    echo $CLUSTER_MEMBERS

    # save comma-seperated set of IP's to a variable
    ip_addresses=$CLUSTER_MEMBERS

fi

# starting here we determine if we bootstrap or join
if [[ -n $ip_addresses ]]; then

    if [[ $ip_addresses == *","* ]]; then
        # join cluster
        echo "Join cluster and set gcomm:// to $ip_addresses"
    else 
        # bootstrap cluster
        echo "Bootstrap service"
        start_new_cluster=true;
    fi

else
    
    # exit when there's no service registered. when troubleshooting make sure that:
    # - service discovery (etcd or consul) is running and is reachable
    # - registor is running on each node
    echo "No service is online or registered. Please make sure that you discovery service is available and running"
    exit 1

fi

# logic to bootstrap or join a cluster.
if [ "$start_new_cluster" = true ] ; then
    exec /docker-entrypoint.sh "$@" --wsrep-new-cluster --wsrep_cluster_address=gcomm://$ip_addresses $WSREP_OPTIONS $DB_OPTIONS
else
    exec /docker-entrypoint.sh "$@" --wsrep_cluster_address=gcomm://$ip_addresses $WSREP_OPTIONS $DB_OPTIONS
fi