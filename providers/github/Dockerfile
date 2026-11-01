FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

ARG RUNNER_VERSION=2.335.1
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

RUN useradd -m -s /bin/bash runner \
    && usermod -aG docker runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/runner

RUN case "${TARGETARCH}" in \
        amd64) ARCH=x64 ;; \
        arm64) ARCH=arm64 ;; \
        *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL --retry 5 --retry-delay 5 --retry-all-errors -o actions-runner.tar.gz \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz" \
    && tar xzf actions-runner.tar.gz \
    && rm actions-runner.tar.gz \
    && ./bin/installdependencies.sh \
    && mkdir -p /home/runner/work \
    && chown -R runner:runner /home/runner

COPY --chmod=755 entrypoint.sh /entrypoint.sh

USER runner

ENTRYPOINT ["/entrypoint.sh"]
