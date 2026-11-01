# OSCR: a self-hosted CI runner in one container

Run the official GitHub Actions runner or Azure Pipelines agent on your own machine, inside a Linux container that has Docker. One container serves one repository and runs one job at a time. It works on any machine that runs Docker: Windows, macOS, or Linux, on x86-64 or arm64.

**For agents.** This page is the runbook. Fetch the raw Markdown at `https://oddessentials.github.io/odd-self-hosted-ci-runtime/agents.md` and follow the steps in order. Each item in step 1 is a choice only the human can make; ask before proceeding.

## 1. Decide

**Who may run code on this machine.** The runner mounts the Docker socket, so any job it executes can control Docker on the host, which is equivalent to root. Use it only for repositories whose contributors you trust, and never let it run pull requests from forks.

**Dedicated or shared machine.** A dedicated box should bring the runner up on boot. A machine you also work on should start the runner deliberately, so it does not take jobs or resources while you are using it. This sets `restart` in step 4.

**Persistent or ephemeral.** A persistent runner stays registered while stopped, so jobs queue until it returns and GitHub cancels those that wait too long. An ephemeral runner registers fresh for each job, exits after it, and relies on the container restarting; it unregisters when stopped. Default to persistent on a shared machine and ephemeral on a dedicated one.

**One runner per repository**, named `oscr-<repo>`. An organization-wide runner is possible but extends the trust decision above to every repository in the organization.

## 2. Prerequisites

- Docker with Compose v2. Windows: Docker Desktop with the WSL 2 backend. macOS: Docker Desktop or OrbStack. Linux: Docker Engine, with your user in the `docker` group.
- Admin access to the target repository, or ownership of the organization for an organization runner.
- Optional: the GitHub CLI, `gh`, to check runner status from a terminal.

## 3. Create a token

One fine-grained personal access token per runner:

1. GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token.
2. Repository access: only the target repository.
3. Repository permissions: **Administration: Read and write**. Metadata is added automatically.
4. Set an expiry and note the date. The runner stops registering when the token lapses.

For an organization runner, grant the organization permission **Self-hosted runners: Read and write** instead of a repository permission.

Azure DevOps: create a personal access token with **Agent Pools: Read & manage**.

## 4. Create the runner

Make a folder for the runner, for example `~/ci/oscr-myrepo`, with two files.

`.env` holds only the token:

```
GITHUB_PAT=github_pat_...
```

`compose.yml`:

```yaml
name: oscr-myrepo
services:
  runner:
    image: oddessentials/oscr-github:latest
    container_name: oscr-myrepo
    env_file: .env
    environment:
      GITHUB_OWNER: your-org-or-user
      GITHUB_REPO: myrepo
      RUNNER_NAME: oscr-myrepo
      RUNNER_LABELS: self-hosted,linux,docker
      RUNNER_PERSISTENT: "true"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - work:/home/runner/work
    stop_grace_period: 60s
    restart: "no"
    cpus: 4
    mem_limit: 8g
volumes:
  work:
```

Adjust it to your decisions:

| Decision | Change |
|---|---|
| Dedicated machine | `restart: unless-stopped` |
| Ephemeral | `RUNNER_PERSISTENT: "false"` together with `restart: unless-stopped`, otherwise the runner stops after its first job |
| Organization runner | Remove `GITHUB_REPO`; add `GITHUB_RUNNER_GROUP` if the group is not `default` |
| Targeting labels | Append to `RUNNER_LABELS`, for example `,gpu` |
| Machine size | `cpus` and `mem_limit` cap this runner; leave headroom for yourself and any other runners |

Azure DevOps uses the same file with `image: oddessentials/oscr-azure-devops:latest`, the work volume mounted at `/home/agent/work`, `ADO_PAT` in `.env`, and `ADO_ORG_URL`, `ADO_POOL`, and optionally `ADO_PROJECT` and `AGENT_LABELS` under `environment`.

Start it and watch the log until the runner reports that it is listening for jobs:

```
docker compose up -d
docker compose logs -f
```

Confirm in the repository under Settings → Actions → Runners, in Azure DevOps under Organization settings → Agent pools, or from a terminal:

```
gh api repos/OWNER/REPO/actions/runners --jq '.runners[] | [.name, .status] | @tsv'
```

## 5. Point a workflow at it

Change `runs-on`, and guard pull-request workflows so forks never reach the runner:

```yaml
jobs:
  build:
    if: github.event.pull_request.head.repo.full_name == github.repository
    runs-on: [self-hosted, linux]
```

Also set Settings → Actions → General → Fork pull request workflows to require approval.

Azure Pipelines: replace `vmImage` with `pool: { name: Default, demands: [docker] }`, using your pool name.

Jobs run as the non-root user `runner` with `sudo` and `docker` available. A job that passes on `ubuntu-latest` should pass here; Windows and macOS jobs cannot. To reach a service on the host machine, use `host.docker.internal` and add `extra_hosts: ["host.docker.internal:host-gateway"]` to the service in `compose.yml`.

The repository's [smoke test workflow](https://github.com/oddessentials/odd-self-hosted-ci-runtime/blob/main/.github/workflows/smoke-test.yml) is a ready-made check: copy it into your repository and run it from the Actions tab.

## 6. Operate

| Action | Command | Effect |
|---|---|---|
| Start | `docker compose up -d` | Registers, replacing a stale entry with the same name, and listens |
| Stop | `docker compose stop` | Finishes the current job, then stops. Persistent: stays registered and shows offline. Ephemeral: unregisters |
| Retire | `docker compose down -v` | Stops and deletes the work volume. A persistent runner must also be removed under Settings → Actions → Runners |
| Update | `docker compose pull && docker compose up -d` | Pulls the new image. The runner also updates itself inside the container |
| Logs | `docker compose logs -f` | |

**On boot.** Docker Desktop starts at login by default and honors `restart` policies, so `unless-stopped` means the runner is up whenever you are logged in. On Linux, `systemctl enable docker` has the same effect. With `restart: "no"` nothing starts until you run `up` again, which is the right setting for a machine you also use.

**Stopping cleanly matters.** `stop` gives the runner 60 seconds to finish and unregister. Quitting Docker Desktop, sleeping the machine, or losing power kills it mid-stop and can leave a dead entry in the runner list. That entry is harmless: the next start replaces it.

**Several runners on one machine.** Use one folder per repository. Resource caps add up across runners, so size them so the machine stays responsive, and start only the ones you need.

**Workspace.** The `work` volume keeps checkouts between jobs for speed. `down -v` wipes it.

## 7. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Container exits at once; log says it failed to get a registration token | Token wrong, expired, or missing Administration | Put a new token in `.env`, then `docker compose up -d --force-recreate` |
| Job stays queued | Runner offline, or labels do not match `runs-on` | `docker compose ps`; compare labels under Settings → Actions → Runners |
| Runner missing after reboot | `restart: "no"` | Start it, or switch to `unless-stopped` |
| `exec format error` | Image for the wrong CPU architecture | `docker compose pull`; images ship for amd64 and arm64 |
| Permission denied on `docker.sock` inside a job | Rootless or non-default Docker socket | Mount your real socket path; `docker context inspect` shows it |
| Job cannot reach `localhost` on the host | Inside the container, `localhost` is the container | Use `host.docker.internal` as described in step 5 |

## Alternative: the orchestrator

The repository ships an orchestrator for anyone who prefers one `.env` and a script: clone it, copy `orchestrator/env.example` to `orchestrator/.env`, fill it in, and run `orchestrator/select-provider.sh start`. It needs bash, manages one provider at a time, and uses the same variables as above.

## Contract

- Linux jobs only, as a non-root user, one job per runner at a time.
- Official runner binaries, unmodified. No autoscaling, no secret management, no emulation of provider features.
- Fork pull requests are never run by default.

Source and issues: [github.com/oddessentials/odd-self-hosted-ci-runtime](https://github.com/oddessentials/odd-self-hosted-ci-runtime)
