#!/bin/bash
# Simple helper to start Enterprise Server using Docker.
# After pulling the image, run this script to start the container.
#
# Usage:
#   ./start-host-es.sh [--network <net>]
#
# By default the script attaches the container to the "bridged-net" network.

# Ensure crash dump folder exists
if [ ! -d /var/crash ]; then
    echo "Creating /var/crash"
    sudo mkdir -p /var/crash
fi

NAME="enterprise-server"
NETWORK="bridged-net"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --network)
            NETWORK="$2"
            shift 2
            ;;
        *)
            echo "Usage: $0 [--network <net>]"
            exit 1
            ;;
    esac
done

docker run -d --network "$NETWORK" \
    --platform linux/amd64 \
    --ulimit core=-1 \
    --restart always \
    --mount type=bind,source=/var/crash,target=/var/crash \
    -e NSP_ACCEPT_EULA="Yes" \
    --mount source=EnterpriseServer-db,target=/var/EBO \
    ghcr.io/schneiderelectricbuildings/ebo-enterprise-server:7.0.2.348

