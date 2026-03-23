# aptrepo-handler

`aptrepo://<app-id>` handler to install software from third-party APT repositories in one click.

Examples:

- `aptrepo://bruno`
- `aptrepo://cursor`

## How It Works

The handler does not execute arbitrary URLs from links.  
It reads a local allowlist configuration per app:

- `/etc/aptrepo-handler/apps.d/<app-id>.conf`

Each config defines:

- the GPG key URL to import
- the `deb ...` repository line to write
- the package name to install

## Project Structure

- `DEBIAN/`: Debian packaging metadata (control, postinst, prerm)
- `usr/bin/aptrepo-handler`: main handler script
- `usr/share/applications/aptrepo-handler.desktop`: URI scheme registration
- `etc/aptrepo-handler/apps.d/*.conf`: allowlisted app configurations
- `install-local.sh`: quick local install script
- `build-aptrepo-handler.sh`: Debian package build script

## For Users

### Install from `.deb`

Install with your package manager UI or with:

```bash
sudo dpkg -i aptrepo-handler_1.0_all.deb
```

If `dpkg` reports missing dependencies:

```bash
sudo apt -f install
```

After installation, test:

```bash
xdg-open 'aptrepo://bruno'
```

### Uninstall

```bash
sudo dpkg -r aptrepo-handler
```

Purge package config files:

```bash
sudo dpkg -P aptrepo-handler
```

## For Developers

### Build the `.deb`

From `packages/aptrepo-handler`:

```bash
chmod +x build-aptrepo-handler.sh
./build-aptrepo-handler.sh
```

Output:

- `aptrepo-handler_1.0_all.deb` (generated in the current directory)

Build with a custom version:

```bash
./build-aptrepo-handler.sh 1.1
```

### Local Installation (dev/test, without `.deb`)

```bash
chmod +x install-local.sh
./install-local.sh
```

This command:

- copies the script to `~/.local/bin/aptrepo-handler`
- copies app configs to `/etc/aptrepo-handler/apps.d/` (via `sudo`)
- registers the `x-scheme-handler/aptrepo` handler

## App Config Format

Example:

```bash
APP_ID="bruno"
DISPLAY_NAME="Bruno"
KEY_URL="https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x9FA6017ECABE0266"
KEYRING_PATH="/etc/apt/keyrings/bruno.gpg"
LIST_FILE_PATH="/etc/apt/sources.list.d/bruno.list"
REPO_LINE="deb [arch=amd64 signed-by=/etc/apt/keyrings/bruno.gpg] http://debian.usebruno.com/ bruno stable"
PACKAGE_NAME="bruno"
```

## Usage

Once installed:

- click an `aptrepo://bruno` link
- confirm the installation
- authenticate (pkexec)
- the script installs the repository and package

## Security

- allowlist-based app IDs (`aptrepo://<id>`)
- no dynamic parameters executed from the URL
- strict app ID validation (`[a-z0-9][a-z0-9._-]*`)
