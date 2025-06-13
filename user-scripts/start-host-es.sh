#!/bin/bash
# Simple helper to start Enterprise Server using the bridged-net network
# After pulling the image, run this script to start the container

# Ensure crash dump folder exists
if [ ! -d /var/crash ]; then
    echo "Creating /var/crash"
    sudo mkdir -p /var/crash
fi

docker run -d --network bridged-net \
    --platform linux/amd64 \
    --ulimit core=-1 \
    --restart always \
    --mount type=bind,source=/var/crash,target=/var/crash \
    -e NSP_ACCEPT_EULA="Yes" \
    --mount source=EnterpriseServer-db,target=/var/EBO \
    ghcr.io/schneiderelectricbuildings/ebo-enterprise-server:7.0.2.348

