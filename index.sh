#!/bin/bash
shopt -s expand_aliases
if [ -z "$NO_COLOR" ]; then
    alias log_info="echo -e \"\033[1;32mINFO\033[0m:\""
    alias log_error="echo -e \"\033[1;31mERROR\033[0m:\""
else
    alias log_info="echo \"INFO:\""
    alias log_error="echo \"ERROR:\""
fi
set -e

SOCI_USER="awslabs"
SOCI_REPO="soci-snapshotter"

response=$(curl -s "https://api.github.com/repos/${SOCI_USER}/${SOCI_REPO}/releases/latest")

LATEST_VERSION=$(echo "$response" | jq -r '.tag_name')


if [[ "$RUNNER_OS" == "Linux" ]]; then
    if [[ "$RUNNER_ARCHITECTURE" == "x64" ]]; then
        log_info "Runner OS: Linux (x64)"
        wget https://github.com/${SOCI_USER}/${SOCI_REPO}/releases/download/${LATEST_VERSION}/${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz && tar -xvf ${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz && cp ./soci /usr/local/bin && cp ./soci-snapshotter-grpc /usr/local/bin
    elif [[ "$RUNNER_OS" == "ARM64" ]]; then
        log_info "Runner OS: Linux (ARM64)"
        wget https://github.com/${SOCI_USER}/${SOCI_REPO}/releases/download/${LATEST_VERSION}/${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-arm64.tar.gz && tar -xvf ${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-arm64.tar.gz && cp ./soci /usr/local/bin && cp ./soci-snapshotter-grpc /usr/local/bin
    else
        log_error "Runner OS: Linux (Unknown Architecture: $RUNNER_ARCHITECTURE)"
        exit 1
    fi
elif [[ "$RUNNER_OS" == "Windows" ]]; then
    if [[ "$RUNNER_ARCHITECTURE" == "x64" ]]; then
        log_info "Runner OS: Windows (x64)"
        exit 1
    else
        log_error "Runner OS: Windows (Unknown Architecture: $RUNNER_ARCHITECTURE)"
        exit 1
    fi
elif [[ "$RUNNER_OS" == "macOS" ]]; then
    if [[ "$RUNNER_ARCHITECTURE" == "x64" ]]; then
        log_info "Runner OS: macOS (x64)"
        exit 1
    else
        log_error "Runner OS: macOS (Unknown Architecture: $RUNNER_ARCHITECTURE)"
        exit 1
    fi
else
    log_error "Unknown Runner OS: $RUNNER_OS"
    log_error "Only Linux binaries are available"
fi

SUDO=
if command -v sudo >/dev/null; then
    SUDO=sudo
    log_info "Sudo functional. Beginngin system installation"
elif [ "$EUID" -eq 0 ]; then
    log_info "Root permissions. Beginngin system installation"
else
    log_info "Sudo not functional and not root. continue with user permissions"
fi
rm index.sh THIRD_PARTY_LICENSES NOTICE.md soci-snapshotter-grpc
# wget https://github.com/${SOCI_USER}/${SOCI_REPO}/releases/download/${LATEST_VERSION}/${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz && tar -xvf ${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz && cp ./soci /usr/local/bin && cp ./soci-snapshotter-grpc /usr/local/bin
# sudo ctr i pull --user AWS:$REGISTRY_PASSWORD $REPOSITORY_TAG
sudo ctr i pull docker.io/library/nginx:latest
sudo soci create docker.io/library/nginx:latest
# ctr i pull --user AWS:$REGISTRY_PASSWORD $REPOSITORY_TAG

# soci create $REPOSITORY_TAG

# soci push --user AWS:$REGISTRY_PASSWORD --platform linux/amd64 $REPOSITORY_TAG