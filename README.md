# 🐝 Odd Self-Hosted CI Runtime (OSCR)

[![CI](https://github.com/oddessentials/odd-self-hosted-ci-runtime/actions/workflows/ci.yml/badge.svg)](https://github.com/oddessentials/odd-self-hosted-ci-runtime/actions/workflows/ci.yml)
[![Pages](https://github.com/oddessentials/odd-self-hosted-ci-runtime/actions/workflows/pages.yml/badge.svg)](https://oddessentials.github.io/odd-self-hosted-ci-runtime/)
[![Publish Docker Images](https://github.com/oddessentials/odd-self-hosted-ci-runtime/actions/workflows/publish.yml/badge.svg)](https://github.com/oddessentials/odd-self-hosted-ci-runtime/actions/workflows/publish.yml)
[![Release](https://img.shields.io/github/v/release/oddessentials/odd-self-hosted-ci-runtime?display_name=tag&sort=semver)](https://github.com/oddessentials/odd-self-hosted-ci-runtime/releases)
[![License](https://img.shields.io/github/license/oddessentials/odd-self-hosted-ci-runtime)](LICENSE)
[![Docker Hub Pulls (GitHub Runner)](https://img.shields.io/docker/pulls/oddessentials/oscr-github?label=docker%20pulls%20github)](https://hub.docker.com/r/oddessentials/oscr-github)
[![Docker Hub Pulls (Azure DevOps Agent)](https://img.shields.io/docker/pulls/oddessentials/oscr-azure-devops?label=docker%20pulls%20azure)](https://hub.docker.com/r/oddessentials/oscr-azure-devops)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
[![semantic-release: angular](https://img.shields.io/badge/semantic--release-angular-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)

The official GitHub Actions runner or Azure Pipelines agent, in one Linux container with Docker, on your own hardware. Any OS that runs Docker, x86-64 or arm64, zero cloud cost.

## Get started

**[Setup and operations guide](https://oddessentials.github.io/odd-self-hosted-ci-runtime/)**: from token to first job, including when to leave a runner running, how it behaves on boot, and how to stop it cleanly.

Working with an AI agent? Point it at the raw guide: `https://oddessentials.github.io/odd-self-hosted-ci-runtime/agents.md`

## Images

| Image | Provider |
|---|---|
| [`oddessentials/oscr-github`](https://hub.docker.com/r/oddessentials/oscr-github) | GitHub Actions |
| [`oddessentials/oscr-azure-devops`](https://hub.docker.com/r/oddessentials/oscr-azure-devops) | Azure DevOps |

Tags: `latest`, `vX.Y.Z`, commit SHA, `YYYYMMDD`. Platforms: `linux/amd64`, `linux/arm64`.

## Development

`make help` lists the lint and build targets. Pull request titles follow Conventional Commits and are squash-merged; see [CONTRIBUTING.md](CONTRIBUTING.md).

## Governance

[INVARIANTS.md](INVARIANTS.md) holds the non-negotiable constraints. [SPEC.md](SPEC.md) holds the specification.

## License

[MIT](LICENSE)
