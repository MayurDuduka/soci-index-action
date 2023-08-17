#!/bin/bash

SOCI_USER="awslabs"
SOCI_REPO="soci-snapshotter"

set -e

shopt -s expand_aliases
if [ -z "$NO_COLOR" ]; then
    alias info_log="echo -e \"\033[1;32mINFO\033[0m:\""
    alias error_log="echo -e \"\033[1;31mERROR\033[0m:\""
else
    alias info_log="echo \"INFO:\""
    alias error_log="echo \"ERROR:\""
fi

RESPONSE=$(curl -s "https://api.github.com/repos/${SOCI_USER}/${SOCI_REPO}/releases/latest")

LATEST_VERSION=$(echo "$RESPONSE" | jq -r '.tag_name')

case "$RUNNER_OS" in
    Linux)
    case "$RUNNER_ARCH" in
        X64)
            wget https://github.com/${SOCI_USER}/${SOCI_REPO}/releases/download/${LATEST_VERSION}/${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz
            wget https://github.com/${SOCI_USER}/${SOCI_REPO}/releases/download/${LATEST_VERSION}/${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz.sha256sum
            sha256sum -c  ${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz.sha256sum;
            tar -xvf ${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz && cp ./soci /usr/local/bin && cp ./${SOCI_REPO}-grpc /usr/local/bin
            ;;
        ARM64)
            wget https://github.com/${SOCI_USER}/${SOCI_REPO}/releases/download/${LATEST_VERSION}/${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-arm64.tar.gz
            wget https://github.com/${SOCI_USER}/${SOCI_REPO}/releases/download/${LATEST_VERSION}/${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-arm64.tar.gz.sha256sum
            sha256sum -c  ${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-arm64.tar.gz.sha256sum;
            tar -xvf ${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-arm64.tar.gz && cp ./soci /usr/local/bin && cp ./${SOCI_REPO}-grpc /usr/local/bin
            ;;
        *)
            error_log "unsupported architecture $RUNNER_ARCH"
            exit 1
            ;;
    esac
    ;;
    *)
        error_log "unsupported OS $RUNNER_OS"
        error_log "Only Linux binaries are available"
        exit 1
        ;;
esac

SUDO=
if command -v sudo >/dev/null; then
    SUDO=sudo
    info_log "Sudo functional. Starting system installation"
elif [ "$EUID" -eq 0 ]; then
    info_log "Root permissions. Starting system installation"
else
    info_log "Sudo not functional and not root. continue with user permissions"
fi

rm index.sh THIRD_PARTY_LICENSES NOTICE.md ${SOCI_REPO}-grpc

# sudo ctr i pull docker.io/library/nginx:latest

# sudo soci create docker.io/library/nginx:latest

info_log "registry name: $REGISTRY"
info_log "repo name: $REPO_NAME"
info_log "tag: $REPOSITORY_TAG"
info_log "tag: $REGISTRY_USER"
info_log "tag: $REGISTRY_PASSWORD"

sudo ctr i pull --user $REGISTRY_USER:$REGISTRY_PASSWORD $REGISTRY/$REPO_NAME:$REPOSITORY_TAG

soci create $REGISTRY/$REGISTRY_NAME:$REPOSITORY_TAG

soci push --user $REGISTRY_USER:$REGISTRY_PASSWORD $REGISTRY/$REPO_NAME:$REPOSITORY_TAG

# soci push --user AWS:$REGISTRY_PASSWORD --platform linux/amd64 $REGISTRY/$REPO_NAME:$REPOSITORY_TAG