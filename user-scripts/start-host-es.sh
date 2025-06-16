#!/bin/bash
# Simple helper to start Enterprise Server using the bridged-net network
# After pulling the image, run this script to start the container

# Ensure crash dump folder exists
if [ ! -d /var/crash ]; then
    echo "Creating /var/crash"
    sudo mkdir -p /var/crash
fi

if [ "$1" = "--swarm" ]; then
    shift
    if docker service create --help 2>&1 | grep -q -- "--platform"; then
        PLATFORM_OPTION="--platform linux/amd64"
    else
        PLATFORM_OPTION=""
    fi
    docker service create --name enterprise-server \
        --hostname enterprise-server \
        --network bridged-net \
        $PLATFORM_OPTION \
        --mount type=bind,source=/var/crash,target=/var/crash \
        -e NSP_ACCEPT_EULA="Yes" \
        --mount source=EnterpriseServer-db,target=/var/EBO \
        ghcr.io/schneiderelectricbuildings/ebo-enterprise-server:7.0.2.348
else
    docker run -d --network bridged-net \
        --platform linux/amd64 \
        --ulimit core=-1 \
        --restart always \
        --mount type=bind,source=/var/crash,target=/var/crash \
        -e NSP_ACCEPT_EULA="Yes" \
        --mount source=EnterpriseServer-db,target=/var/EBO \
        ghcr.io/schneiderelectricbuildings/ebo-enterprise-server:7.0.2.348
fi

