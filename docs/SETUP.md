# Setup (from scratch)

This repo is meant to go from **fresh DigitalOcean Ubuntu droplet → Tailscale-only access** to:

- OpenCode WebUI
- Login Portal (browser in a tab)

## 0) Prereqs

- A DigitalOcean account
- A Tailscale tailnet
- (Recommended) MagicDNS enabled in Tailscale

## 1) Make sure this repo is public (recommended)

Cloud-init will `git clone` the repo. Public avoids embedding GitHub credentials into droplet user-data.

## 2) Create a Tailscale auth key

Tailscale Admin → **Settings → Keys** → create an auth key.

## 3) Create droplet using cloud-init

DigitalOcean → Create Droplet → Ubuntu LTS → Advanced Options → **User data**.

Paste the contents of:

- `cloud-init/cloud-init.yaml.tmpl`

Replace placeholders:

- `__TAILSCALE_AUTHKEY__`
- `__OPENCODE_PASSWORD__`
- `__YOUR_REPO_GIT_URL__` (example: `https://github.com/casettek/kbx-hq.git`)

Then create the droplet.

## 4) Verify bootstrap on the droplet

SSH in (root) and run:

```bash
tail -n 200 /var/log/cloud-init-output.log
tailscale status
tailscale ip -4
sudo ufw status verbose
docker compose -f /opt/kbx-hq/compose.yml ps
```

## 5) Access services (from any Tailscale device)

- OpenCode: `http://<magicdns-or-tailscale-ip>:4096`
- Login Portal: `http://<magicdns-or-tailscale-ip>:3001`
- File Browser: `http://<magicdns-or-tailscale-ip>:8001`

Note: OpenCode is served through a small reverse-proxy (Caddy) to set a browser-compatible
Content Security Policy (CSP) so the WebUI terminal’s WASM worker can run.

To (re)start everything after a reboot or update:

```bash
cd /opt/kbx-hq
./scripts/up.sh
```

In particular, the terminal uses a WASM payload that may be loaded via `data:` URLs, so the
effective CSP must allow:

- `script-src` with `'unsafe-eval'` and `'wasm-unsafe-eval'`
- `connect-src` with `data:`

## 6) Day-2 usage

On the droplet:

```bash
cd /opt/kbx-hq
docker compose -f compose.yml logs -f --tail=200
```

To allow a new TCP port `XXXX` over Tailscale only:

```bash
sudo ufw allow in on tailscale0 to any port XXXX proto tcp
```

If you frequently spin up ad-hoc dev servers, you can allow a port range over Tailscale only
(less secure, more convenient). Example: allow `8000-8099`:

```bash
sudo ufw allow in on tailscale0 to any port 8000:8099 proto tcp
```

This repo does not run OpenCode in a container. If you start ad-hoc dev servers on the host, make
sure you bind to `0.0.0.0` (not `127.0.0.1`) and allow the port on `tailscale0`.

## Run OpenCode on the host

1) Install OpenCode:

```bash
cd /opt/kbx-hq
./scripts/install_opencode.sh
```

2) Ensure `/opt/kbx-hq/.env` has:

- `OPENCODE_INTERNAL_HOSTNAME=127.0.0.1`
- `OPENCODE_INTERNAL_PORT=4097`

3) Install systemd unit:

```bash
sudo cp /opt/kbx-hq/systemd/opencode.service /etc/systemd/system/opencode.service
sudo sed -i "s/REPLACE_WITH_USER/kbx/g" /etc/systemd/system/opencode.service
sudo systemctl daemon-reload
sudo systemctl enable --now opencode
```

4) Start containers (Caddy + Login Portal):

```bash
cd /opt/kbx-hq
sudo -u kbx bash -lc "./scripts/up.sh"
```

## Run File Browser on the host (no auth)

This runs File Browser against the same directory as the OpenCode workspace:

- Root: `/srv/agent/opencode-workspace`
- Port: `8001` (within the default allowed range `8000-8099` on `tailscale0`)

```bash
cd /opt/kbx-hq
./scripts/install_filebrowser.sh

sudo cp /opt/kbx-hq/systemd/filebrowser.service /etc/systemd/system/filebrowser.service
sudo sed -i "s/REPLACE_WITH_USER/kbx/g" /etc/systemd/system/filebrowser.service
sudo systemctl daemon-reload
sudo systemctl enable --now filebrowser
```

Note: your service must bind to a reachable interface (for example `0.0.0.0:PORT`). If it binds
to `127.0.0.1:PORT` (localhost only), it will not be reachable via `http://<tailscale-name>:PORT`.

Also note: anything you start **inside the OpenCode container** is not reachable from the host
or Tailscale unless you explicitly publish that container port in `compose.yml`.

Recommended pattern for ad-hoc servers:

- run them on the **host**, from a directory under `/srv/agent/opencode-workspace/...`
- bind to `0.0.0.0`
- allow the port (or port range) on `tailscale0`

## 7) Dropbox sync (Maestral)

This keeps host `/srv/agent/dropbox` synced with Dropbox (good for a small markdown KB).

The directory is mounted into containers as:

- OpenCode: `/home/opencode/workspace/dropbox`
- Login Portal: `/dropbox`

### Install

```bash
sudo apt-get update
sudo apt-get install -y pipx
pipx ensurepath
pipx install maestral
```

Re-open your SSH session (or `source ~/.profile`) so `pipx` apps are on `PATH`.

### Link Dropbox

```bash
maestral link
```

### Set sync folder and start

```bash
maestral config set path /srv/agent/dropbox
maestral start
maestral status
```

### Run on boot (systemd)

```bash
sudo cp /opt/kbx-hq/systemd/maestral.service /etc/systemd/system/maestral.service
sudo sed -i "s/REPLACE_WITH_USER/kbx/g" /etc/systemd/system/maestral.service
sudo systemctl daemon-reload
sudo systemctl enable --now maestral
systemctl status maestral --no-pager
```
