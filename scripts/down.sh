#!/bin/bash

if [ -f docker-compose.yml ]; then
    docker-compose -f docker-compose.yml down
else
    echo "docker-compose.yml does not exist"
fi