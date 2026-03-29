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

For Ubuntu-derivative repositories (like PPAs), `REPO_LINE` may include a codename placeholder:

```bash
REPO_LINE="deb [signed-by=/etc/apt/keyrings/my-app.gpg] https://ppa.launchpadcontent.net/vendor/ppa/ubuntu __UBUNTU_CODENAME__ main"
```

Supported placeholders:

- `__UBUNTU_CODENAME__`
- `${UBUNTU_CODENAME}`
- `$UBUNTU_CODENAME`

At install time, the handler resolves this to the Ubuntu base codename detected on the machine (works for Ubuntu and Linux Mint).

## Usage

Once installed:

- click an `apt-thirdparty://my-app` link
- confirm the initial action
- authenticate (pkexec)
- if no local app config exists yet, the script refreshes the signed whitelist, then asks a second explicit confirmation with exact package/repository details before installing
- install repository and package

## Security

- allowlist-based app IDs (`apt-thirdparty://<id>`)
- no dynamic parameters executed from the URL
- strict app ID validation (`[a-z0-9][a-z0-9._-]*`)
- signed whitelist refresh (GPG detached signature)
- automatic first-run key bootstrap over HTTPS (can be overridden with preinstalled trusted keyring)

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
- `https://example.com/apt-thirdparty/whitelist-signing.pub` (only if local trusted keyring is missing)

### Trust key installation (client side)

By default, this step is automatic.  
If `/usr/share/apt-thirdparty-handler/trustedkeys.gpg` is missing, the handler downloads:

- `${WHITELIST_BASE_URL}/whitelist-signing.pub` (or `WHITELIST_KEY_URL` if explicitly configured),

then dearmors it and installs the trusted keyring before signature verification.

Manual installation is still possible:

```bash
curl -fsSL https://example.com/apt-thirdparty/whitelist-signing.pub \
  | gpg --dearmor \
  | sudo tee /usr/share/apt-thirdparty-handler/trustedkeys.gpg >/dev/null
```

### Publisher workflow (server side)

Whitelist publication is managed in `phramusca.github.io`.

Prepare an `apps.d` directory containing one `*.conf` per app in that repository, e.g.:

```bash
apps.d/
  my-app.conf
```

Build + sign the bundle from `phramusca.github.io`:

```bash
./tools/build-whitelist-bundle.sh ./.apt-thirdparty/apps.d "you@example.com" ./apt-thirdparty
```

This produces:

- `apt-thirdparty/apps.tar`
- `apt-thirdparty/apps.tar.asc`

Publish both files at your `WHITELIST_BASE_URL`.

### Generate a signing key (GPG)

Create key:

```bash
gpg --full-generate-key
```

Recommended choices for this project:

- key type: `ECC (sign only)`
- curve: `Curve 25519` (default)
- expiration: e.g. `1y` (renewable)
- set a strong passphrase (20+ chars, unique, stored in a password manager)

Even for local publishing, a passphrase is recommended: if the machine is compromised,
an unprotected private signing key can be used immediately.

Export public key for clients:

```bash
gpg --armor --export "you@example.com" > whitelist-signing.pub
```

### Copy the signing key to another machine

Use one identity on every machine where you publish; copy the **secret** key (it stays passphrase-protected).

On the source machine, find the key ID

```bash
gpg --list-secret-keys --with-fingerprint
```

then:

```bash
gpg --armor --export-secret-keys KEYID > signing-secret.asc
```

Transfer `signing-secret.asc` over a trusted channel (encrypted USB, `scp`, etc.—not email or a git repo). On the destination:

```bash
gpg --import signing-secret.asc
shred -u signing-secret.asc   # or rm after a secure wipe
```

Keep a separate encrypted backup if you need recovery after disk loss.

### Expiration and rotation

With a short expiry (e.g. `1y`), plan before the key expires.

**Extend the same key** (recommended if nothing is compromised): fingerprint stays the same.

```bash
gpg --edit-key KEYID
# gpg> expire
# gpg> save
gpg --armor --export "you@example.com" > whitelist-signing.pub
```

Republish `whitelist-signing.pub`. Clients must refresh the public key material in `trustedkeys.gpg` (re-import the updated armored public key into that keyring, or remove the keyring only if you are sure the next download from `WHITELIST_KEY_URL` is trustworthy).

**Switch to a new signing key**: generate a new key; during overlap, publish both public keys in one file, e.g. `gpg --armor --export OLDKEYID NEWKEYID > whitelist-signing.pub`; sign bundles with the new secret key; after clients have updated, remove the old public key from the published file and from client keyrings.
