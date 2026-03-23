# apt-thirdparty-handler

`apt-thirdparty://<app-id>` handler to install software from third-party APT repositories in one click.

Examples:

- `apt-thirdparty://bruno`
- `apt-thirdparty://cursor`

## How It Works

The handler does not execute arbitrary URLs from links.  
It reads a local allowlist configuration per app:

- `/etc/apt-thirdparty-handler/apps.d/<app-id>.conf`

Each config defines:

- the GPG key URL to import
- the `deb ...` repository line to write
- the package name to install

## For Users

### Install from `.deb`

Install with your package manager UI or with:

```bash
sudo dpkg -i apt-thirdparty-handler_1.0_all.deb
```

If `dpkg` reports missing dependencies:

```bash
sudo apt -f install
```

After installation, test:

```bash
xdg-open 'apt-thirdparty://bruno'
```

### Uninstall

```bash
sudo dpkg -r apt-thirdparty-handler
```

Purge package config files:

```bash
sudo dpkg -P apt-thirdparty-handler
```

## For Developers

### Build the `.deb`

From the repository root:

```bash
chmod +x build-apt-thirdparty-handler.sh
./build-apt-thirdparty-handler.sh
```

Output:

- `apt-thirdparty-handler_<version>_all.deb` (generated at repository root)

Build with a custom version:

```bash
./build-apt-thirdparty-handler.sh 1.1
```

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

- click an `apt-thirdparty://bruno` link
- confirm the installation
- authenticate (pkexec)
- the script installs the repository and package

## Security

- allowlist-based app IDs (`apt-thirdparty://<id>`)
- no dynamic parameters executed from the URL
- strict app ID validation (`[a-z0-9][a-z0-9._-]*`)
