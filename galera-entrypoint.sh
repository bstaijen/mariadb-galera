#!/bin/bash

[ "$DEBUG" == 'true' ] && set -x

set -e

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
        echo "Join cluster and set gcomm:// to $VAR"
        CLUSTER_ADDRESS="gcomm://$VAR?pc.wait_prim=no"
    else 
        # BOOTSTRAP
        echo "Bootstrap service"
        start_new_cluster=true;
        CLUSTER_ADDRESS="gcomm://";
    fi

else
    echo "No service is online or registered"
    exit 1
fi

# Create Galera Config
config_file="/etc/mysql/conf.d/galera.cnf"

cat <<EOF > $config_file
[mysqld]
skip-host-cache
skip-name-resolve
skip-external-locking
bind-address                    = 0.0.0.0
port                            = 3306
datadir					        = /var/lib/mysql
tmpdir					        = /tmp
socket					        = /var/run/mysqld/mysqld.sock


default-storage-engine          = innodb
innodb_autoinc_lock_mode        = 2
innodb-flush-log-at-trx-commit  = 0

binlog_format                   = ROW
wsrep_on                        = ON
query_cache_size                = 0
query_cache_type                = 0

# Error Logging
log-error	                    = /dev/stderr
log_warnings		            = 3

# Galera Provider Configuration
wsrep_provider                  = /usr/lib/libgalera_smm.so

# Galera Cluster Configuration
wsrep_cluster_name              = "$CLUSTER_NAME" 
wsrep_cluster_address           = $CLUSTER_ADDRESS

# Galera Synchronization Congifuration
wsrep_sst_auth                  = "$GALERA_USER:$GALERA_PASS" 
wsrep_sst_method                = rsync

# TODO
#ssl-ca	                        = /etc/mysql/ssl/ca-cert.pem
#ssl-cert                       = /etc/mysql/ssl/server-cert.pem
#ssl-key	                    = /etc/mysql/ssl/server-key.pem

[mysql_safe]
log-error	                    = /dev/stderr
log_warnings                    = 3
pid-file	                    = /var/run/mysqld/mysqld.pid
socket		                    = /var/run/mysqld/mysqld.sock
nice		                    = 0
EOF

if [ "$start_new_cluster" = true ] ; then
    exec /docker-entrypoint.sh "$@" --wsrep-new-cluster
else
    exec /docker-entrypoint.sh "$@"
fi