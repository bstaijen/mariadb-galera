# Quick Start Guide

### Use with docker-compose
I've created a few sample docker-compose files to run the demo with different service discovery backends.

#### etcd
Create a docker-compose.yml file with the following content (if you want to use etcd):
```
version: '2'
services:
    db:
        build: .
        restart: always
        environment:
        - "MYSQL_ROOT_PASSWORD=yourpassword"
        - "CLUSTER_NAME=galeracluster"
        - "SERVICE_NAME=test-galera-db"
        - "BACKEND=etcd"
        - "affinity:com.mariadb.host!=galeracluster"
        depends_on: 
            - registrator
        labels:
        - "com.mariadb.host=galeracluster"
        ports:
        - 3306:3306
        - 4567-4568:4567-4568
        - 4444:4444
    registrator:
        image: gliderlabs/registrator:master
        hostname: registrator
        depends_on: 
            - etcd
        volumes:
        - "/var/run/docker.sock:/tmp/docker.sock"
        command: -internal etcd://etcd:2379
        restart: always
        environment:
        - "affinity:com.mariadb.host!=registrator"
        labels:
        - "com.mariadb.host=registrator"
    etcd:
        image: "quay.io/coreos/etcd:v3.1.0"
        hostname: etcd
        ports: 
        - 2379-2380:2379-2380
        - 4001:4001
        - 7001:7001
        command: etcd -advertise-client-urls=http://etcd:2379,http://etcd:4001,http://127.0.0.1:2379,http://127.0.0.1:4001 -listen-client-urls=http://0.0.0.0:2379,http://0.0.0.0:4001
        restart: always
```

#### consul
Create a docker-compose.yml file with the following content (if you want to use consul):
```
version: '2'
services:
    db:
        build: .
        restart: always
        environment:
        - "MYSQL_ROOT_PASSWORD=yourpassword"
        - "CLUSTER_NAME=galeracluster"
        - "SERVICE_NAME=test-galera-db"
        - "BACKEND=consul"
        - "affinity:com.mariadb.host!=galeracluster"
        depends_on: 
            - registrator
        labels:
        - "com.mariadb.host=galeracluster"
        ports:
        - 3306:3306
        - 4567-4568:4567-4568
        - 4444:4444
    registrator:
        image: gliderlabs/registrator:master
        hostname: registrator
        depends_on: 
            - consul
        volumes:
        - "/var/run/docker.sock:/tmp/docker.sock"
        command: -internal consul://consul:8500
        restart: always
        environment:
        - "affinity:com.mariadb.host!=registrator"
        labels:
        - "com.mariadb.host=registrator"
    consul:
        image: "progrium/consul:latest"
        hostname: "consul"
        ports:
        - "8400:8400"
        - "8500:8500"
        - "8600:53/udp"
        command: "-server -bootstrap -ui-dir /ui"
        restart: always
```

### Tips
- When using docker-compose in co-operation with docker swarm you have to make sure that registrator is running on each machine.
- See the scripts documentation to help you set-up or start a cluster even quicker.