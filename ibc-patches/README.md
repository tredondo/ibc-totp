# IBC Patches

This folder contains patches applied to the upstream IBC (Interactive Brokers Controller) source.

## Patches

### totp-patch

Adds automatic TOTP (Time-based One-Time Password) generation for 2FA login.

**What it does:**
- Detects "Mobile Authenticator app" prompts
- Generates 6-digit TOTP codes using the `googleauth` library
- Auto-fills the code and clicks OK

**Required:**
- `googleauth-1.5.0.jar` in `IBC/lib/` (downloaded via script)

## Applying Patches

When upgrading IBC to a new version:

1. Download and extract new IBC source:
   ```bash
   rm -rf IBC-new
   git clone https://github.com/IbcAlpha/IBC.git IBC-new
   cd IBC-new
   ```

2. Apply patches:
   ```bash
   git am < ../ibkr/ibc-patches/ibc-patch-totp.patch
   ```

3. Download external libraries:
   ```bash
   ../ibkr/scripts/download-deps.sh ibc
   ```

4. Build:
   ```bash
   ant clean dist
   ```

5. Copy built files to docker:
   ```bash
   cp resources/IBC.jar ../ibkr/docker/IBC/
   cp lib/*.jar ../ibkr/docker/IBC/lib/
   cp -r resources/scripts ../ibkr/docker/IBC/
   ```

## Creating New Patches

After making changes to IBC source:

```bash
cd IBC
git add -A
git commit -m "Your commit message"
git format-patch -1 --stdout > ../ibkr/ibc-patches/ibc-patch-description.patch
```
