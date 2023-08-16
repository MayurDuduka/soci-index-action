#!/bin/bash -l
SOCI_USER="awslabs"
SOCI_REPO="soci-snapshotter"

response=$(curl -s "https://api.github.com/repos/${SOCI_USER}/${SOCI_REPO}/releases/latest")

LATEST_VERSION=$(echo "$response" | jq -r '.tag_name')

wget https://github.com/${SOCI_USER}/${SOCI_REPO}/releases/download/${LATEST_VERSION}/${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz && tar -xvf ${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz && cp ./soci /usr/local/bin && cp ./soci-snapshotter-grpc /usr/local/bin
sudo ctr i pull --user AWS:$REGISTRY_PASSWORD $REPOSITORY_TAG
sudo ctr i pull nginx:latest
sudo soci create nginx:latest
# ctr i pull --user AWS:$REGISTRY_PASSWORD $REPOSITORY_TAG

# soci create $REPOSITORY_TAG

# soci push --user AWS:$REGISTRY_PASSWORD --platform linux/amd64 $REPOSITORY_TAG