FROM mcr.microsoft.com/devcontainers/base:ubuntu22.04

ARG TARGETOS
ARG TARGETARCH

# Install python3-pip to ensure pip is available for python3
RUN apt-get update && \
  apt-get install -y --no-install-recommends python3-pip && \
  rm -rf /var/lib/apt/lists/*
