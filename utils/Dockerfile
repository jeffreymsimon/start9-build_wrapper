# Utility container for squashfs operations
# Used internally by the build process for s9pk packaging

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install --no-install-recommends -y squashfs-tools-ng && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
