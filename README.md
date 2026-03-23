# apt-thirdparty-handler

`apt-thirdparty://<app-id>` handler to install software from third-party APT repositories in one click.

Example:

- `apt-thirdparty://my-app`

## How It Works

The handler does not execute arbitrary URLs from links.  
It reads a local allowlist configuration per app:

- `/etc/apt-thirdparty-handler/apps.d/<app-id>.conf`
- optionally refreshes this allowlist from a signed remote bundle

Each config defines:

- the GPG key URL to import
- the `deb ...` repository line to write
- the package name to install

By default, app definitions come from the signed remote allowlist.  
You can update the allowlist without shipping a new `.deb` by publishing a signed `apps.tar`.

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
xdg-open 'apt-thirdparty://my-app'
```

Refresh signed whitelist manually:

```bash
sudo apt-thirdparty-handler --refresh-index
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
APP_ID="my-app"
DISPLAY_NAME="My App"
KEY_URL="https://example.com/repo/signing-key.asc"
KEYRING_PATH="/etc/apt/keyrings/my-app.gpg"
LIST_FILE_PATH="/etc/apt/sources.list.d/my-app.list"
REPO_LINE="deb [arch=amd64 signed-by=/etc/apt/keyrings/my-app.gpg] https://example.com/repo stable main"
PACKAGE_NAME="my-app"
```

## Usage

Once installed:

- click an `apt-thirdparty://my-app` link
- confirm the installation
- authenticate (pkexec)
- the script refreshes whitelist if needed (signed bundle), then installs repository and package

## Security

- allowlist-based app IDs (`apt-thirdparty://<id>`)
- no dynamic parameters executed from the URL
- strict app ID validation (`[a-z0-9][a-z0-9._-]*`)
- signed whitelist refresh (GPG detached signature)

## Remote Whitelist Updates

### Client-side configuration

Edit:

- `/etc/apt-thirdparty-handler/whitelist.conf`

Minimum config:

```bash
WHITELIST_BASE_URL="https://example.com/apt-thirdparty"
WHITELIST_REFRESH_INTERVAL_SEC=86400
```

The handler will fetch:

- `https://example.com/apt-thirdparty/apps.tar`
- `https://example.com/apt-thirdparty/apps.tar.asc`

### Trust key installation (client side)

You must install the public key used to sign whitelist bundles:

```bash
curl -fsSL https://example.com/apt-thirdparty/whitelist-signing.pub \
  | gpg --dearmor \
  | sudo tee /usr/share/apt-thirdparty-handler/trustedkeys.gpg >/dev/null
```

### Publisher workflow (server side)

Prepare an `apps.d` directory containing one `*.conf` per app, e.g.:

```bash
apps.d/
  my-app.conf
```

Build + sign the bundle:

```bash
chmod +x tools/build-whitelist-bundle.sh
./tools/build-whitelist-bundle.sh ./apps.d "you@example.com" ./out
```

This produces:

- `out/apps.tar`
- `out/apps.tar.asc`

Publish both files at your `WHITELIST_BASE_URL`.

### Generate a signing key (GPG)

Create key:

```bash
gpg --full-generate-key
```

Export public key for clients:

```bash
gpg --armor --export "you@example.com" > whitelist-signing.pub
```

### About minisign vs GPG

- **GPG**: already available on most Linux systems, supports keyrings and detached signatures; this project uses GPG.
- **minisign**: lighter and simpler signature tool, but requires extra dependency on client machines.

If you want, minisign support can be added later as an optional verifier.
