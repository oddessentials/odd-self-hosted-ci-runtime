FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

ARG AGENT_VERSION=4.266.2
ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    jq \
    libicu70 \
    libssl3 \
    unzip \
    zip \
    sudo \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL --retry 5 --retry-delay 5 --retry-all-errors https://get.docker.com | sh

RUN useradd -m -s /bin/bash agent \
    && usermod -aG docker agent \
    && echo "agent ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/agent

RUN case "${TARGETARCH}" in \
        amd64) ARCH=x64 ;; \
        arm64) ARCH=arm64 ;; \
        *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL --retry 5 --retry-delay 5 --retry-all-errors -o /tmp/vsts-agent.tar.gz \
    "https://download.agent.dev.azure.com/agent/${AGENT_VERSION}/vsts-agent-linux-${ARCH}-${AGENT_VERSION}.tar.gz" \
    && tar xzf /tmp/vsts-agent.tar.gz \
    && rm /tmp/vsts-agent.tar.gz \
    && mkdir -p /home/agent/work \
    && chown -R agent:agent /home/agent

COPY --chmod=755 entrypoint.sh /entrypoint.sh

USER agent

ENTRYPOINT ["/entrypoint.sh"]
