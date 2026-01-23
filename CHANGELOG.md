# Changelog

All notable changes to OSCR will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.7.0](https://github.com/oddessentials/odd-self-hosted-ci-runtime/compare/v1.6.1...v1.7.0) (2026-01-23)

### Features

* add gpu ([4b89400](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/4b89400d09854d223b198d677ae6d0229218b50b))

## [1.6.1](https://github.com/oddessentials/odd-self-hosted-ci-runtime/compare/v1.6.0...v1.6.1) (2026-01-23)

### Bug Fixes

* ai review ([46e7376](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/46e7376848fd85db15e2cf1ca038c8c6fb738239))
* ensure ai-reviewer capability is available in ([b59280a](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/b59280ad90f6353e7b518cfd6c18afd33e476146))

## [1.6.0](https://github.com/oddessentials/odd-self-hosted-ci-runtime/compare/v1.5.0...v1.6.0) (2026-01-22)

### Features

* implement cross-platform YAML linting and ADO onboarding docs ([adebc8f](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/adebc8fd1eb6daebcdd06a3dfac0de5c22896ad9))

### Bug Fixes

* azure example ([4697e15](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/4697e156a4353f0dcb4bf4d98b53dc01baa91bb9))

## [1.5.0](https://github.com/oddessentials/odd-self-hosted-ci-runtime/compare/v1.4.2...v1.5.0) (2026-01-22)

### ⚠ BREAKING CHANGES

* **azure-devops:** None - all changes are additive

### Features

* **azure-devops:** add enterprise parity with GitHub provider ([1677681](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/1677681da5a5bc5aaa2ec73dbb6c6b1292c5e301))

## [1.4.2](https://github.com/oddessentials/odd-self-hosted-ci-runtime/compare/v1.4.1...v1.4.2) (2026-01-21)

### Bug Fixes

* auto-pull and warm up Ollama model on sidecar startup ([c785b08](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/c785b0867b60c01e0b8a73d253d97b1408d81810))

## [1.4.1](https://github.com/oddessentials/odd-self-hosted-ci-runtime/compare/v1.4.0...v1.4.1) (2026-01-20)

### Bug Fixes

* updat entrypoint ([8107937](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/810793735f4d305f363cf60b8be56a55ee4bfd18))

## [1.4.0](https://github.com/oddessentials/odd-self-hosted-ci-runtime/compare/v1.3.0...v1.4.0) (2026-01-20)

### Features

* pin semgrep version and add Ollama integration guide ([a856b8c](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/a856b8c129dc775fe7b9cb6c1fb719c658f1a5c5))

## [1.3.0](https://github.com/oddessentials/odd-self-hosted-ci-runtime/compare/v1.2.0...v1.3.0) (2026-01-20)

### Features

* add ollama-sidecar network alias + install semgrep ([d327a17](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/d327a173326bb475c16db1304034c760497f80bb))

## [1.2.0](https://github.com/oddessentials/odd-self-hosted-ci-runtime/compare/v1.1.0...v1.2.0) (2026-01-20)

### Features

* llama to orch ([b9a320e](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/b9a320eea3bf0eac1be762b39c7671d1572886f6))

## [1.1.0](https://github.com/oddessentials/odd-self-hosted-ci-runtime/compare/v1.0.0...v1.1.0) (2026-01-20)

### Features

* add python3 and pip to runner images for Semgrep support ([b5b4f3f](https://github.com/oddessentials/odd-self-hosted-ci-runtime/commit/b5b4f3f156e040093a29f1a33a836da7a095e7ba))

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
