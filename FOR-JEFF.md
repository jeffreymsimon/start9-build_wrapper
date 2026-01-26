# StartOS Build Action: DevOps for StartOS Packages

## What This Project Does

This is a GitHub Action that provides a complete build environment for StartOS 0.4.x packages. Instead of every service developer figuring out how to install the SDK, configure Docker, set up QEMU for cross-compilation, and manage developer keys - they add one line to their workflow and everything just works.

**Before this action:**
```yaml
# 50+ lines of setup steps
# Different for every developer
# Breaks when SDK changes
# Hard to maintain
```

**After this action:**
```yaml
- uses: jeffreymsimon/start9-build_wrapper@main
# Done. Build environment ready.
```

## The Technical Architecture

```
GitHub Actions Workflow
         ↓
start9-build_wrapper Action
         │
         ├── Node.js 22 (SDK compilation)
         ├── Docker + Buildx (container builds)
         ├── QEMU (cross-architecture emulation)
         ├── start-cli (StartOS packaging tool)
         └── Developer Key (package signing)
         │
         ↓
Service Repository
         │
         ├── make
         ↓
.s9pk Package (multi-architecture)
```

## The Codebase Structure

```
start9-build_wrapper/
├── action.yaml              # The GitHub Action definition
├── Dockerfile               # Standalone container build environment
├── buildService.yml         # Drop-in CI workflow template
├── releaseService.yml       # Drop-in release workflow template
├── utils/
│   └── Dockerfile           # squashfs utility container
└── .github/workflows/
    └── sdk-utils.yaml       # Internal: publishes utils container
```

## What This Enables

### For Service Developers

**Continuous Integration:**
```yaml
# .github/workflows/build.yml
name: Build
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: jeffreymsimon/start9-build_wrapper@main
      - run: make
      - uses: actions/upload-artifact@v4
        with:
          name: package
          path: "*.s9pk"
```

Every push builds the package. Every PR verifies it compiles. No manual testing of "does it still build?"

**Automated Releases:**
```yaml
# .github/workflows/release.yml
on:
  push:
    tags: ['v*']
jobs:
  release:
    steps:
      - uses: jeffreymsimon/start9-build_wrapper@main
      - run: make
      - run: gh release create ${{ github.ref_name }} *.s9pk
```

Push a tag, get a GitHub Release with the .s9pk attached. No manual release process.

## The Clever Parts

### Dynamic Binary Download

The action detects your environment and downloads the right `start-cli`:

```bash
ARCH=$(uname -m)  # x86_64 or aarch64
OS=$(uname -s | tr '[:upper:]' '[:lower:]')  # linux or darwin

# Fetches latest release
curl -s https://api.github.com/repos/Start9Labs/start-cli/releases/latest | jq ...
```

Works on Linux runners, macOS runners, ARM runners, Intel runners - automatically.

### Manifest-Driven Automation

Instead of hardcoding package names:

```bash
# Extract metadata from the built package itself
MANIFEST=$(start-cli s9pk inspect "$S9PK" manifest)
PACKAGE_ID=$(echo "$MANIFEST" | jq -r '.id')
VERSION=$(echo "$MANIFEST" | jq -r '.version')
```

The workflow adapts to whatever you build.

### Developer Key Management

StartOS packages must be signed. The action handles this automatically:

```bash
mkdir -p ~/.startos
if [ ! -f ~/.startos/developer.key.pem ]; then
  start-cli init-key
fi
```

First run generates a key. Subsequent runs reuse it. No manual key management.

### Optional Registry Publishing

```bash
if [[ -z "$S9USER" || -z "$S9PASS" || -z "$S9REGISTRY" ]]; then
  echo "Publish skipped: missing registry credentials."
else
  start-cli publish ...
fi
```

If you have registry credentials, it publishes. If not, it gracefully skips. The workflow succeeds either way.

## What You Can Learn From This Project

### 1. Composite Actions Simplify Complexity

A GitHub composite action bundles multiple steps into one reusable unit. Users don't see the complexity - they see one `uses:` line.

### 2. Dynamic Toolchain Installation

Detecting OS/architecture and downloading the right binary is more maintainable than maintaining multiple action versions.

### 3. Graceful Degradation

Optional features (like registry publishing) shouldn't break mandatory features (like building). Check for prerequisites and skip gracefully.

### 4. Template Workflows

Providing ready-to-use workflow files (`buildService.yml`, `releaseService.yml`) lowers the barrier to adoption. Copy, paste, done.

### 5. Multi-Architecture from Day One

Setting up QEMU and Docker Buildx by default means every package supports both x86_64 and aarch64. No extra work for developers.

## The Evolution

This action started as a fork of `remcoros/startos-sdk-action` (for StartOS 0.3.x). The 0.4.x SDK is fundamentally different:
- Different CLI tool (`start-cli` vs previous)
- Different package format
- Different build process

The refactoring required understanding both versions and building a bridge for the community.

## Why This Matters

StartOS package development has a steep learning curve. This action flattens it:

| Without This Action | With This Action |
|---------------------|------------------|
| Install Node.js | One `uses:` line |
| Install Docker | |
| Configure Buildx | |
| Set up QEMU | |
| Download start-cli | |
| Initialize developer key | |
| Figure out build flags | |
| Debug cross-compilation | |

The 30 minutes (or hours) of setup become 30 seconds.

## The Container Alternative

Not using GitHub Actions? The Dockerfile provides the same environment:

```bash
docker build -t startos-build .
docker run -v $(pwd):/service startos-build make
```

Same result, different platform.

## What This Project Represents

This is infrastructure for infrastructure. It's not a StartOS package itself - it's the tool that makes building StartOS packages easy.

The goal: every developer can publish high-quality StartOS packages with automated CI/CD, without being a DevOps expert.
