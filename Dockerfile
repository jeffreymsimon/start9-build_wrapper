# StartOS 0.4.x Build Environment
# This Dockerfile provides a container-based build environment for StartOS 0.4.x packages
# Note: The primary build method uses the GitHub Action (action.yaml), but this Dockerfile
# can be used for local container-based builds or other CI systems.

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        clang \
        libclang-dev \
        squashfs-tools-ng \
        qemu-user-static \
        ca-certificates \
        curl \
        git \
        jq \
        nodejs \
        npm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install start-cli (latest version)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        ARCH_NAME="x86_64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        ARCH_NAME="aarch64"; \
    fi && \
    BINARY_NAME="start-cli-${ARCH_NAME}-unknown-linux-musl" && \
    ASSET_NAME="${BINARY_NAME}.tar.gz" && \
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/Start9Labs/start-cli/releases/latest | jq -r '.assets[] | select(.name=="'$ASSET_NAME'") | .browser_download_url') && \
    curl -L "$DOWNLOAD_URL" -o /tmp/start-cli.tar.gz && \
    tar xzf /tmp/start-cli.tar.gz -C /tmp && \
    mv /tmp/$BINARY_NAME /usr/local/bin/start-cli && \
    chmod +x /usr/local/bin/start-cli && \
    rm /tmp/start-cli.tar.gz

# Initialize developer key
RUN mkdir -p ~/.startos && \
    start-cli init-key

WORKDIR /workspace
