# Docker Container for Auto Clustering and Replication MariaDB Server
This is a demo for running a simplified, auto clustering and replication MariaDB Server in Docker.

## How does it work?
This project consists out of one docker image. The docker image depends on consul for service discovery. The demo uses [gliderlabs/registrator](https://github.com/gliderlabs/registrator) for its service registration. If set-up in the right way the database will cluster and replicate itself.

## Requirements
- `[gliderlabs/docker-consul](https://github.com/gliderlabs/docker-consul)` - For MariaDB Server Discovery
- `[gliderlabs/registrator](https://github.com/gliderlabs/registrator)` - For Automatic Server Registration
- `[mariadb-disover-tool](https://github.com/bstaijen/mariadb-discover-tool)` - For querying Consul Registry

## Environment Arguments
- `MYSQL_ROOT_PASSWORD` - Root user password. eg: `MYSQL_ROOT_PASSWORD=password`
- `CLUSTER_NAME` - Name of the cluster. eg: `CLUSTER_NAME=galeracluster`
- `CONSUL_HOST` - Link to consul instance. eg: `CONSUL_HOST=consul:8500`
- `SERVICE_NAME` - Name of the service. eg: `SERVICE_NAME=galera-db`
- `SERVICE_TAGS` - Tags for the service. eg: `SERVICE_TAGS=galera-db-tag`

## Usage

### Docker Swarm and Docker Compose
- `docker-compose up -d --force-recreate`
- `docker-compose scale registrator=7` - Or any number of machines you have.
- I suggest waiting for 15-30 seconds so the first database server can configure itself.
- `docker-compose scale db=3`
- I suggest waiting a few seconds so the nodes can come online.
- `docker exec -it <container_id> bash`
- `mysql -uroot -ppassword`
- `SHOW STATUS LIKE 'wsrep_cluster_size';`

### Kubernetes
- TODO

### One machine
- TODO

# Feedback & Issues
- TODO

# License
- TODO