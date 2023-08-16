#!/bin/bash

SOCI_USER="awslabs"
SOCI_REPO="soci-snapshotter"

set -e

shopt -s expand_aliases
if [ -z "$NO_COLOR" ]; then
    alias log_info="echo -e \"\033[1;32mINFO\033[0m:\""
    alias log_error="echo -e \"\033[1;31mERROR\033[0m:\""
else
    alias log_info="echo \"INFO:\""
    alias log_error="echo \"ERROR:\""
fi

RESPONSE=$(curl -s "https://api.github.com/repos/${SOCI_USER}/${SOCI_REPO}/releases/latest")

LATEST_VERSION=$(echo "$RESPONSE" | jq -r '.tag_name')

case ${{ runner.os }} in
    Linux)
    case ${{ runner.arch }} in
        X64)
            wget https://github.com/${SOCI_USER}/${SOCI_REPO}/releases/download/${LATEST_VERSION}/${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz
            wget https://github.com/${SOCI_USER}/${SOCI_REPO}/releases/download/${LATEST_VERSION}/${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz.sha256sum
            sha256sum -c  ${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz.sha256sum;
            tar -xvf ${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz && cp ./soci /usr/local/bin && cp ./soci-snapshotter-grpc /usr/local/bin
            ;;
        ARM64)
            wget https://github.com/${SOCI_USER}/${SOCI_REPO}/releases/download/${LATEST_VERSION}/${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-arm64.tar.gz
            wget https://github.com/${SOCI_USER}/${SOCI_REPO}/releases/download/${LATEST_VERSION}/${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-arm64.tar.gz.sha256sum
            sha256sum -c  ${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-arm64.tar.gz.sha256sum;
            tar -xvf ${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-arm64.tar.gz && cp ./soci /usr/local/bin && cp ./soci-snapshotter-grpc /usr/local/bin
            ;;
        *)
            log_error "unsupported architecture $arch"
            exit 1
            ;;
    esac
    ;;
    *)
        log_error "unsupported OS ${{ runner.os }}"
        log_error "Only Linux binaries are available"
        exit 1
        ;;
esac

SUDO=
if command -v sudo >/dev/null; then
    SUDO=sudo
    log_info "Sudo functional. Starting system installation"
elif [ "$EUID" -eq 0 ]; then
    log_info "Root permissions. Starting system installation"
else
    log_info "Sudo not functional and not root. continue with user permissions"
fi

rm index.sh THIRD_PARTY_LICENSES NOTICE.md soci-snapshotter-grpc

# sudo ctr i pull --user AWS:$REGISTRY_PASSWORD $REPOSITORY_TAG
sudo ctr i pull docker.io/library/nginx:latest
sudo soci create docker.io/library/nginx:latest

# soci create $REPOSITORY_TAG

# soci push --user AWS:$REGISTRY_PASSWORD --platform linux/amd64 $REPOSITORY_TAG