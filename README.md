# IBKR TWS Docker Setup

Automated Trader Workstation (TWS) container with IBC controller for hands-free trading.

## Overview

This project runs Interactive Brokers' Trader Workstation in a Docker container with:

- **IBC** (Interactive Brokers Controller) - Automates TWS/Gateway login and dialog handling
- **Automatic 2FA** - TOTP code generation for secure login
- **VNC Access** - Remote desktop via port 5901
- **X11/Xvfb** - Headless X11 for GUI operation

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Docker Container                    │
│                                                         │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌───────┐ │
│  │  Xvfb   │───▶│ Openbox │───▶│  Tint2  │───▶│ x11vnc│ │
│  └─────────┘    └─────────┘    └─────────┘    └───────┘ │
│       │                                                 │
│       ▼                                                 │
│  ┌─────────────────────────────────────────────────┐    │
│  │              IBC (Java Controller)              │    │
│  │  • Login automation (user/password/TOTP)        │    │
│  │  • Dialog handlers (API, warnings, etc)         │    │
│  │  • Session management                           │    │
│  └─────────────────────┬───────────────────────────┘    │
│                        │                                │
│                        ▼                                │
│  ┌─────────────────────────────────────────────────┐    │
│  │         TWS / Gateway (Java Application)        │    │
│  │  • Trading platform                             │    │
│  │  • API server (port 7496)                       │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
└─────────────────────────────────────────────────────────┘
         │                                    │
         │                                    ▼
    Port 5901                           Port 7496
    (VNC)                              (API)
```

## Quick Start

### 1. Configure Secrets

Create `docker/tws.secrets`:

```bash
TWS_USERNAME=your_username
TWS_PASSWORD=your_password
TWS_TOTP_SECRET=your_base32_totp_secret
```

### 2. Build and Run

```bash
cd docker
docker compose up -d
```

### 3. Access

- **VNC**: Connect to `localhost:5901` (password: none)
- **API**: Connect to `localhost:7496`

## Configuration

### docker/tws.secrets

| Variable | Description |
|----------|-------------|
| `TWS_USERNAME` | IBKR account username |
| `TWS_PASSWORD` | IBKR account password |
| `TWS_TOTP_SECRET` | Base32-encoded TOTP secret for 2FA |

### docker/ibc-config.ini

Key settings in the IBC configuration:

| Setting | Default | Description |
|---------|---------|-------------|
| `AcceptIncomingConnectionAction` | `accept` | Auto-accept API connections |
| `AllowBlindTrading` | `yes` | Auto-accept blind trading |
| `TradingMode` | `live` | `live` or `paper` |
| `AutoRestartTime` | `07:00 AM` | Daily auto-restart |
| `AutoLogoffTime` | `06:45 AM` | Daily logoff |

### 2FA Setup

1. Get your TOTP secret from IBKR (during 2FA setup or from account settings)
2. The secret is Base32 encoded (letters A-Z, 2-7)
3. Example: `JBSWY3DPEHPK3PXP`

## File Structure

```
.
├── docker/
│   ├── Dockerfile              # Container build
│   ├── docker-compose.yaml     # Container orchestration
│   ├── tws.secrets            # Credentials (gitignored)
│   ├── ibc-config.ini          # IBC settings
│   ├── ibkr-entrypoint.sh     # Container entrypoint
│   ├── ibc-start.sh           # IBC + TWS launcher
│   ├── java-wrapper.sh        # Java wrapper
│   └── IBC/                   # Built IBC with TOTP support
│       ├── IBC.jar
│       ├── lib/               # External libs (downloaded)
│       │   └── googleauth-1.5.0.jar
│       └── scripts/
│           └── ibcstart.sh
├── IBC/                        # IBC source (git submodule or clone)
│   ├── src/                   # Source code
│   ├── build.xml              # Ant build
│   └── lib/                   # External libs (downloaded)
│       └── googleauth-1.5.0.jar
├── scripts/
│   └── download-deps.sh       # Download external dependencies
├── ibc-patches/               # Source patches
│   └── ibc-patch-totp.patch
├── flake.nix                   # Nix dev environment
└── AGENTS.md                   # Development notes
```

## Development

### Prerequisites

```bash
nix develop
```

### Building IBC from Source

```bash
# Download external dependencies first
./scripts/download-deps.sh ibc

# Build IBC
cd IBC
ant clean dist
```

### Nix Commands

```bash
nix develop              # Enter dev shell
nix develop -c ant dist  # Build without entering shell
nix flake update         # Update dependencies
```

## Upgrading IBC

The IBC source modifications are stored in `ibc-patches/`. To upgrade:

1. Download new IBC release from https://github.com/IbcAlpha/IBC
2. Extract to `IBC/` folder
3. Apply patches:
   ```bash
   cd IBC
   git am < ../ibc-patches/*.patch
   ```
4. Download dependencies:
   ```bash
   ../ibkr/scripts/download-deps.sh ibc
   ```
5. Rebuild:
   ```bash
   ant clean dist
   ```
6. Copy built files to `docker/IBC/`:
   ```bash
   cp resources/IBC.jar ../ibkr/docker/IBC/
   cp lib/*.jar ../ibkr/docker/IBC/lib/
   cp -r resources/scripts ../ibkr/docker/IBC/
   ```

   Or use the download script to get Docker deps:
   ```bash
   ../ibkr/scripts/download-deps.sh docker
   ```

## Logs

Container logs are written to `/home/tws/` inside the container:

```bash
docker exec ibkr-tws-prod tail -f /home/tws/ibc-out-*.log
```

## Port Reference

| Port | Service | Description |
|------|---------|-------------|
| 5901 | VNC | Remote desktop access |
| 7496 | API | TWS API (live trading) |
| 7497 | API | TWS API (paper trading) |

## Security Notes

- `docker/tws.secrets` contains sensitive credentials - never commit it
- API port should be firewalled appropriately
- Consider using a VPN for remote API access
