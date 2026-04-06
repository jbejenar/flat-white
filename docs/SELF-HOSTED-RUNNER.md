# Self-Hosted Runner Setup — flat-white

This guide covers setting up a self-hosted GitHub Actions runner for flat-white quarterly builds. Use this when free GitHub-hosted runners (7GB RAM, 2 cores) are insufficient — e.g., private repos without free runner access, or if future G-NAF releases grow beyond free runner capacity.

## Hardware Requirements

| Resource | Minimum | Recommended | Notes                                                                                     |
| -------- | ------- | ----------- | ----------------------------------------------------------------------------------------- |
| RAM      | 8 GB    | 16 GB       | NSW (largest state, ~4.6M addresses) peaks at ~5-6 GB. 16 GB provides comfortable margin. |
| CPU      | 2 cores | 4 cores     | gnaf-loader spatial joins are CPU-bound. More cores reduce load time.                     |
| Disk     | 30 GB   | 50 GB       | G-NAF download (~6.5 GB) + Admin Boundaries (~1.5 GB) + Postgres data + output.           |
| Network  | 10 Mbps | 50+ Mbps    | Download step fetches ~8 GB from data.gov.au.                                             |

### Software Prerequisites

- Docker Engine 24+ (with BuildKit)
- GitHub Actions runner agent ([docs](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners))
- Git with submodule support

## Runner Setup

### 1. Install the GitHub Actions Runner

Follow the [official guide](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners) to register a self-hosted runner with your fork/copy of the flat-white repository.

```bash
# Download and configure (from your repo's Settings → Actions → Runners → New self-hosted runner)
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.321.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.321.0/actions-runner-linux-x64-2.321.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.321.0.tar.gz

./config.sh --url https://github.com/YOUR_ORG/flat-white --token YOUR_TOKEN --labels flat-white,high-memory
```

### 2. Add Runner Labels

Label your runner so the workflow can target it. The quarterly build workflow accepts a `runner` input:

- `flat-white` — identifies this as a flat-white-capable runner
- `high-memory` — optional, indicates >7 GB RAM available

### 3. Start the Runner

```bash
# Run as a service (recommended for unattended operation)
sudo ./svc.sh install
sudo ./svc.sh start

# Or run interactively for testing
./run.sh
```

### 4. Verify Docker Access

The runner user must have Docker access:

```bash
# Add runner user to docker group
sudo usermod -aG docker $(whoami)

# Verify
docker run --rm hello-world
```

## Workflow Configuration

The quarterly build workflow supports both free and self-hosted runners via the `runner` input parameter.

### Manual Dispatch (self-hosted)

```bash
# Trigger a build on your self-hosted runner
gh workflow run quarterly-build.yml \
  -f gnaf_version=2026.05 \
  -f runner=self-hosted

# Or target a specific label
gh workflow run quarterly-build.yml \
  -f gnaf_version=2026.05 \
  -f runner=high-memory
```

### Manual Dispatch (free runners — default)

```bash
# Default: uses ubuntu-latest (free GitHub-hosted runners)
gh workflow run quarterly-build.yml -f gnaf_version=2026.05
```

### Scheduled Runs

Scheduled (cron) runs always use `ubuntu-latest` (free runners). To use self-hosted runners for scheduled builds, fork the workflow and change the default `runner` value or use a separate cron-triggered workflow that dispatches with `runner=self-hosted`.

## Cost Estimates

| Option                        | Cost             | Notes                                                                                         |
| ----------------------------- | ---------------- | --------------------------------------------------------------------------------------------- |
| GitHub free runners           | $0               | Public repos only. 7 GB RAM, 2 cores. ~24 min total (9 parallel jobs).                        |
| Self-hosted (existing server) | $0 (electricity) | Reuse existing infrastructure. Runner agent is lightweight.                                   |
| Self-hosted (cloud VM)        | ~$5-15/month     | Run on-demand for ~1 hour/quarter. e.g., AWS `m6i.xlarge` (16 GB, 4 cores) at ~$0.19/hr spot. |
| GitHub larger runners         | $0.008/min       | 16 GB runner: ~$12/build. Only available for orgs/enterprise.                                 |

For most users, free runners are sufficient. The P4.07 memory tuning (shared_buffers=256MB, work_mem=64MB) keeps NSW builds within 7 GB.

## Troubleshooting

### Runner not picking up jobs

- Verify runner is online: repo Settings → Actions → Runners
- Check labels match the `runner` input value
- Ensure runner service is running: `sudo ./svc.sh status`

### Docker permission denied

```bash
sudo usermod -aG docker $USER
# Log out and back in, or:
newgrp docker
```

### OOM kills on self-hosted runner

If you see exit code 137 despite having >7 GB RAM:

- Check Docker memory limits: `docker info | grep Memory`
- Ensure no Docker `--memory` flag is restricting container RAM
- The PostgreSQL tuning in `docker-entrypoint.sh` assumes 7 GB total; on larger machines it still works but doesn't exploit extra memory. Adjust `shared_buffers` and `effective_cache_size` in the entrypoint for larger machines.

### Disk space issues

```bash
# Check available space
df -h

# Clean Docker artifacts
docker system prune -f
docker volume prune -f
```

The build needs ~30 GB free: ~8 GB for downloads, ~15 GB for Postgres data, ~5 GB for output files. Space is reclaimed when the container exits.
