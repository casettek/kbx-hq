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

Note: OpenCode is served through a small reverse-proxy (Caddy) to set a browser-compatible
Content Security Policy (CSP) so the WebUI terminal’s WASM worker can run.

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

This repo also publishes `8000-8099` from the OpenCode container to the host, so servers started
from the OpenCode terminal can be reachable (as long as you bind to `0.0.0.0` and use a port in
that range).

Note: your service must bind to a reachable interface (for example `0.0.0.0:PORT`). If it binds
to `127.0.0.1:PORT` (localhost only), it will not be reachable via `http://<tailscale-name>:PORT`.

Also note: anything you start **inside the OpenCode container** is not reachable from the host
or Tailscale unless you explicitly publish that container port in `compose.yml`.

Recommended pattern for ad-hoc servers:

- run them on the **host**, from a directory under `/srv/agent/opencode-workspace/...`
- bind to `0.0.0.0`
- allow the port (or port range) on `tailscale0`

## 7) Dropbox sync (Maestral)

This keeps `/srv/agent/dropbox` synced with Dropbox (good for a small markdown KB).

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
