# Docker Container for Auto Clustering and Replication a MariaDB Server
This is a demo for running a replicating and auto clustering MariaDB Server with Docker.
Docker hub : [bstaijen/mariadb-galera-cluster](https://hub.docker.com/r/bstaijen/mariadb-galera-cluster/)

## How does it work?
This project consists out of one docker image. The docker image depends on consul for service discovery. The demo uses [gliderlabs/registrator](https://github.com/gliderlabs/registrator) for its service registration. If set-up in the right way the database will start replicating and clustring itself.

## Requirements
- [gliderlabs/docker-consul](https://github.com/gliderlabs/docker-consul) - For MariaDB Server Discovery
- [gliderlabs/registrator](https://github.com/gliderlabs/registrator) - For Automatic Server Registration
- [mariadb-disover-tool](https://github.com/bstaijen/mariadb-discover-tool) - For querying Consul Registry

## Environment Arguments
- `MYSQL_ROOT_PASSWORD` - Root user password. eg: `MYSQL_ROOT_PASSWORD=password`
- `CLUSTER_NAME` - Name of the cluster. eg: `CLUSTER_NAME=galeracluster`
- `CONSUL_HOST` - Link to consul instance. eg: `CONSUL_HOST=consul:8500`
- `SERVICE_NAME` - Name of the service. eg: `SERVICE_NAME=galera-db`
- `SERVICE_TAGS` - Tags for the service. eg: `SERVICE_TAGS=galera-db-tag`
- `DEBUG` - For debugging shell scipt. eg: `DEBUG=true`

## Usage

### With Docker Swarm and Docker Compose
Tested with: `Docker Client Version: 1.12.3` and `Docker Server Version: swarm/1.2.5` and `Docker Compose Version: 1.8.1`

- `docker-compose up -d --force-recreate`
- `docker-compose scale registrator=7` - Or any number of machines you have.
- I suggest waiting for 15-30 seconds so the first database server can configure itself.
- `docker-compose scale db=3`
- I suggest waiting a few seconds so the nodes can come online.
- `docker exec -it <container_id> bash` - Replace `<container_id>` with the id of your database container
- `mysql -uroot -ppassword`
- `SHOW STATUS LIKE 'wsrep_cluster_size';` - The value of wsrep_cluster_size should be equal to the number of db instances

## debugging
- TODO

### With Kubernetes
- TODO

### On One machine
- TODO

# Feedback & Issues
- TODO

# License?
- TODO

# To Do List
- Add Galera Arbitrator
- Write blog posts about using Auto Clustering a MariaDB Server
- Research Security & Generating SSL Certificates
- Research using [Flocker](https://clusterhq.com/flocker/introduction/) for data persistence
- Research Data Backups & Data Peristency & Data Recovery
- Research possibilities of replacing [mariadb-disover-tool](https://github.com/bstaijen/mariadb-discover-tool)  with [Consul-Template](https://github.com/hashicorp/consul-template)
    - if using [mariadb-disover-tool](https://github.com/bstaijen/mariadb-discover-tool) then also support etcd and zookeeper
- Research using MaxScale
- Research Loadbalancing
- Research Healthchecks
- Research Monitoring