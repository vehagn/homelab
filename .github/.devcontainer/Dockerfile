FROM mcr.microsoft.com/devcontainers/base:ubuntu22.04
ARG TARGETOS
ARG TARGETARCH

# Install python3-pip and Node.js LTS
RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends \
  python3-pip \
  curl \
  ca-certificates \
  gnupg \
  lsb-release && \
  # Add NodeSource repository for Node.js LTS
  curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
  # Install Node.js (includes npm)
  apt-get install -y nodejs && \
  # Clean up
  rm -rf /var/lib/apt/lists/*

# Install Gemini CLI and Claude Code globally with pinned versions
RUN npm install -g @google/gemini-cli@0.1.9 @anthropic-ai/claude-code@1.0.48

# Verify installations
RUN node --version && npm --version && python3 --version && pip3 --version && gemini --version && claude --version
