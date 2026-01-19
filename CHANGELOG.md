# Changelog

All notable changes to OSCR will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## 1.0.0 (2026-01-19)

### Features

* add automated Docker image publishing to Docker Hub ([b5f97f5](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/b5f97f5a293eda2fabf1bb599fb19673e3e8aa98))
* add semantic-release and commitlint for automated versioning ([95cbe63](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/95cbe6381441d16a182c9fe0f798af68b590734f))

### Bug Fixes

* add retry logic to Dockerfile network operations ([91ad267](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/91ad267e73615daadf41c59eabc518972f3dcf14))
* download agent from GitHub releases instead of Azure CDN ([904bf55](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/904bf555eaf07091d8f03372655834c39f66461e))
* implement prefetch + COPY pattern for Azure agent ([809c263](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/809c26338a0c3c37ffc5477e4705550487c5c29f))
* pre-download Azure agent to avoid buildx DNS issues ([9cebc6b](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/9cebc6bf5e5b2b9583b5fb58dbf37d16dc4d179e))
* resolve CI quality gate failures ([48be4f1](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/48be4f1b2dadb1a5c5d8b177c0dc47e43c8063b6))
* resolve semantic-release Date.prototype.toString error ([fbcbbfc](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/fbcbbfceedac2220fd61f16a31c692d61a57dac2))
* use correct Microsoft download URL for Azure agent ([a784ead](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/a784ead3101e8ce14be7129437df15f9db57d73b))
* use GitHub releases mirror for Azure DevOps agent download ([ec635b1](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/ec635b1cd5f0eee6f6ef92ef74f1a3f94c630f69))
* use Google DNS to resolve Azure CDN in buildx ([07c177b](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/07c177b29212cc2b448364a4a7c7f45dcecf4906))
* use multi-stage build to avoid Azure CDN DNS issues ([38e4c67](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/38e4c676cdd8765da86e6a6fe56bac6c5ebdf2c4))
* use semantic-release-action for proper output capture ([4c73b2d](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/4c73b2d6db434131d939ff37456e2560de19540b))

### Refactoring

* simplify Dockerfile to use direct curl download ([1a74924](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/1a7492462b4eb082da807d2923fd9bff62cca8cf))
