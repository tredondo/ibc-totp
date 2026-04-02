# IBC Development Guide

## Overview

IBC (Interactive Brokers Controller) automates Trader Workstation/Gateway operation. This project provides a Nix-based development environment for building IBC from source.

## Quick Start

```bash
# Enter the dev shell (auto-installs TWS on first run)
nix develop

# Build IBC for Linux
cd IBC && ant dist
```

Build artifacts appear in `IBC/dist/IBCLinux-3.23.0.zip`.

## Architecture

### Build Dependencies

- **ant** - Apache Ant (build tool)
- **openjdk21** - Java 21 (IBC targets Java 8 bytecode)
- **curl, unzip** - For downloading TWS installer

### TWS Jars Requirement

IBC requires TWS (Trader Workstation) jar files for compilation. The `build.xml` expects:

```
IBC_BIN=/path/to/tws-jars/1044/jars
```

This directory must contain jars like `jts4launch-*.jar` and `twslaunch-*.jar`.

### Automatic TWS Setup

The `shellHook` in `flake.nix` auto-downloads TWS:

```bash
TWS_JARS_DIR="$PWD/tws-jars/1044/jars"
```

On first `nix develop`, it:
1. Downloads the TWS standalone installer
2. Patches it to use system Java instead of bundled JRE
3. Installs to `tws-jars/1044/`
4. Extracts required jars

## Nix Commands

| Command | Purpose |
|---------|---------|
| `nix develop` | Enter dev shell with all build tools |
| `nix develop -c ant dist` | Build directly without entering shell |
| `nix flake update` | Update nixpkgs input |

## Build Targets

```bash
# Inside IBC/
ant compile    # Compile source → IBC/target/classes
ant jar        # Create IBC.jar in IBC/resources/
ant dist       # Create Linux/Windows/Macos zip files
```

## Docker Integration

The built `IBCLinux-*.zip` contains everything needed for Linux deployment:

```
IBCLinux-3.23.0.zip
├── IBC.sh              # Start script
├── IBCConfig.sh        # Config script
├── ibcstart.sh         # Launch script
├── IBC.jar             # Main application
├── config.ini          # Default config
├── LICENSE.txt
└── scripts/
    └── scripts_unix/   # Unix-specific scripts
```

See `docker/Dockerfile` for the complete Docker build process that:
1. Uses `nixos/nix` base image
2. Installs JavaFX (for GUI)
3. Sets up X11/vnc for headless operation
4. Copies IBC resources

## Directory Structure

```
.
├── flake.nix           # Nix dev environment
├── IBC/                # Cloned source repo
│   ├── build.xml       # Ant build file
│   ├── src/            # Java source
│   ├── resources/      # Resources + IBC.jar output
│   └── dist/           # Distribution zip files
│       └── IBCLinux-3.23.0.zip
└── tws-jars/           # TWS installation (downloaded)
    └── 1044/jars/      # IBC_BIN points here
```
