#!/bin/bash

[ "$DEBUG" == 'true' ] && set -x

set -e

# prepend mysqld to arguments
COMMAND=${1:-'mysqld'}

# var start_new_cluster: decides if we should bootstrap or join cluster.
start_new_cluster=false

# env CONSUL_HOST is mandatory
if [[ -z ${CONSUL_HOST} ]]; then
  echo >&2 'error: CONSUL_HOST environment variable is mandatory'
  exit 1
fi

# env SERVICE_NAME is mandatory
if [[ -z ${SERVICE_NAME} ]]; then
  echo >&2 'error: SERVICE_NAME environment variable is mandatory'
  exit 1
fi

# give the registrator some time to register the container. 
sleep 10

# Save IPs to ip_addresses
ip_addresses="`./docker-entrypoint-initdb.d/discovery-tool -address=${CONSUL_HOST} -service=${SERVICE_NAME}-3306`"
echo $ip_addresses

if [ -n "$ip_addresses" ]; then
    
    if [[ $ip_addresses == *","* ]]; then
        # join cluster
        echo "Join cluster and set gcomm:// to $ip_addresses"
        CLUSTER_ADDRESS="gcomm://$ip_addresses?pc.wait_prim=no"
    else 
        # bootstrap cluster
        echo "Bootstrap service"
        start_new_cluster=true;
        CLUSTER_ADDRESS="gcomm://";
    fi

else
    # there went something wrong because there is no service available. Make sure that consul is running.
    echo "No service is online or registered. Please make sure that consul is available and running"
    exit 1
fi

# create galera config
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
log-error                       = /dev/stderr
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

# logic to bootstrap or join a cluster.
if [ "$start_new_cluster" = true ] ; then
    exec /docker-entrypoint.sh "$@" --wsrep-new-cluster
else
    exec /docker-entrypoint.sh "$@"
fi