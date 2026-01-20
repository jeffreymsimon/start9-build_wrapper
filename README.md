# StartOS 0.4.x Build Action

A GitHub Action that provides `start-cli` for packaging services for StartOS 0.4.x. This sets up the complete build environment including Node.js, Docker Buildx, QEMU for multi-architecture builds, and the StartOS CLI tools.

> **Note**: This action is for StartOS **0.4.x** packages only. For 0.3.x packages, see [remcoros/startos-sdk-action](https://github.com/remcoros/startos-sdk-action).

## Usage

To use this action in your GitHub workflow, add it to your workflow file (`.github/workflows/*.yml`):

```yaml
name: Build My Service
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Prepare StartOS SDK
        uses: jeffreymsimon/start9-build_wrapper@main

      - name: Checkout code
        uses: actions/checkout@v4

      - name: Install dependencies
        run: npm ci

      - name: Build package
        run: make
```

### Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `start-cli-version` | Version of start-cli to install | `latest` |

To pin a specific version:

```yaml
- name: Prepare StartOS SDK
  uses: jeffreymsimon/start9-build_wrapper@main
  with:
    start-cli-version: v0.4.0-alpha.17
```

## What's Included

The action installs:
- **Node.js 22** - For TypeScript SDK compilation
- **start-cli** - The StartOS 0.4.x packaging CLI
- **Docker Buildx** - For building multi-architecture container images
- **QEMU** - For cross-platform emulation
- **squashfs-tools-ng** - For s9pk packaging
- **jq** - For JSON parsing
- **Build tools** - clang, libclang-dev, build-essential

## Drop-in Workflows

This repository includes ready-to-use workflow templates:

### [buildService.yml](buildService.yml)

Continuous Integration workflow that builds your package on every commit and pull request.

Copy this file to `.github/workflows/buildService.yml` in your service repository.

Features:
- Triggers on push/PR to main/master branches
- Builds the .s9pk package
- Uploads the package as a build artifact
- Shows SHA256 checksum in logs

### [releaseService.yml](releaseService.yml)

Automated release workflow triggered by version tags.

Copy this file to `.github/workflows/releaseService.yml` in your service repository.

Usage:
```bash
git tag v1.0.0
git push origin v1.0.0
```

Features:
- Builds the .s9pk package
- Generates SHA256 checksum file
- Creates GitHub Release with release notes from manifest
- Optionally publishes to a StartOS registry

#### Registry Publishing (Optional)

To enable automatic publishing to a StartOS registry, set these repository secrets:

| Secret | Description |
|--------|-------------|
| `S9USER` | Registry username |
| `S9PASS` | Registry password |
| `S9REGISTRY` | Registry address (e.g., `registry.start9.com`) |

**Important**: Enter the registry address without `https://` prefix.

If any credentials are missing, the publish step is skipped gracefully.

## Requirements

Your StartOS 0.4.x package repository should have:
- A `Makefile` with a default target that builds the `.s9pk`
- A `package.json` with `@start9labs/start-sdk` dependency
- TypeScript manifest at `startos/manifest.ts`

## Dockerfile

A `Dockerfile` is also provided for container-based builds outside of GitHub Actions. This can be useful for:
- Local development builds
- Other CI systems (GitLab CI, Jenkins, etc.)
- Testing the build environment

```bash
docker build -t startos-builder .
docker run -v $(pwd):/workspace startos-builder make
```

## Differences from 0.3.x

StartOS 0.4.x uses a completely different build system:

| Feature | 0.3.x | 0.4.x |
|---------|-------|-------|
| CLI Tool | `start-sdk` | `start-cli` |
| SDK Language | Rust | TypeScript |
| Package Format | Docker-based | LXC-based |
| Manifest | `manifest.yaml` | `startos/manifest.ts` |
| Dependencies | Cargo | npm |

## License

MIT License - See [LICENSE](LICENSE) for details.

## Credits

Forked from [remcoros/startos-sdk-action](https://github.com/remcoros/startos-sdk-action) and refactored for StartOS 0.4.x.
