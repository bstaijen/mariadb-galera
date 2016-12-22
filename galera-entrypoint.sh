#!/bin/bash

set -e
set -x

COMMAND=${1:-'mysqld'}

# var
start_new_cluster=false

if [[ -z ${CONSUL_HOST} ]]; then
  echo >&2 'error: CONSUL_HOST is not specified '
  exit 1
fi

if [[ -z ${SERVICE_NAME} ]]; then
  echo >&2 'error: SERVICE_NAME is not specified '
  exit 1
fi

# Save IPs to VAR
VAR="`./docker-entrypoint-initdb.d/discovery-tool -h=${CONSUL_HOST} -servicename=${SERVICE_NAME}-3306`"
echo $VAR

# Give the registrator some time to register the container
for i in {15..0}; do
    echo "Discovery in progress... $i"

    VAR2="`./docker-entrypoint-initdb.d/discovery-tool -h=${CONSUL_HOST} -servicename=${SERVICE_NAME}-3306`"
    if [ "$VAR" = "$VAR2" ]; then 
        sleep 1
    else
        # TODO : Think about running for 30sec without break.
        # Because user might scale to a number of N containers and
        # we want to be able to wait for all the registrations to finish.
        echo "New registered containers found!"  
        VAR="`./docker-entrypoint-initdb.d/discovery-tool -h=${CONSUL_HOST} -servicename=${SERVICE_NAME}-3306`"
        break
    fi;

done

if [ -n "$VAR" ]; then
    
    if [[ $VAR == *","* ]]; then
        # 
        echo "Join cluster and set gcomm:// string to $VAR"
        CLUSTER_ADDRESS="gcomm://$VAR?pc.wait_prim=no"
    else 
        # BOOTSTRAP
        echo "Bootstrap"
        start_new_cluster=true;
        CLUSTER_ADDRESS="gcomm://";
    fi

else
    echo "Nobody is online or registered"
fi

# Create Galera Config
config_file="/etc/mysql/conf.d/galera.cnf"

cat <<EOF > $config_file
[mysqld]
query_cache_size=0
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
query_cache_type=0
bind-address=0.0.0.0
wsrep_on=ON

# Galera Provider Configuration
wsrep_provider=/usr/lib/libgalera_smm.so

# Galera Cluster Configuration
wsrep_cluster_name = "$CLUSTER_NAME" 
wsrep_cluster_address = $CLUSTER_ADDRESS

# Galera Synchronization Congifuration
wsrep_sst_auth = "$GALERA_USER:$GALERA_PASS" 
wsrep_sst_method = rsync
EOF

if [ "$start_new_cluster" = true ] ; then
    exec /docker-entrypoint.sh "$@" --wsrep-new-cluster
else
    exec /docker-entrypoint.sh "$@"
fi