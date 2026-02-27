# kbx-hq

Bootstrap a new DigitalOcean Ubuntu droplet into a Tailscale-only “agent workstation” with:

- OpenCode WebUI (container)
- Login Portal (browser-in-a-tab via noVNC/KasmVNC) with a persistent profile
- Optional Dropbox sync scaffold (Maestral, runs on host)

Everything is designed so **ports are reachable only over Tailscale** (you access `http://<magicdns>:PORT`).

## Ports

- OpenCode: `4096` (container listens on 4096)
- Login Portal: `3001` (container listens on 3000 internally)

You can change these in `.env`.

## Quick start (fresh Ubuntu droplet)

### 0) Create droplet

- Ubuntu LTS (22.04+ recommended)
- Add your SSH key

### 1) Clone and configure

```bash
sudo apt-get update && sudo apt-get install -y git
git clone <YOUR_GITHUB_REPO_URL> kbx-hq
cd kbx-hq

cp .env.example .env
$EDITOR .env
```

### 2) Bootstrap host (Docker + Tailscale + directories)

```bash
./scripts/bootstrap_ubuntu.sh
```

### 3) Bring up Tailscale

Interactive login:

```bash
sudo tailscale up
```

Or if you use an auth key:

```bash
sudo tailscale up --auth-key <TS_AUTHKEY>
```

### 4) Lock down ports to Tailscale only

```bash
sudo ./scripts/configure_firewall.sh
```

### 5) Start the services

```bash
./scripts/up.sh
```

### 6) Access from any Tailscale device

Use MagicDNS name if enabled (recommended), otherwise use `tailscale ip -4`.

- OpenCode: `http://<droplet-name>:${OPENCODE_PORT}`
- Login Portal: `http://<droplet-name>:${LOGIN_PORTAL_PORT}`

## Dropbox sync (optional)

This repo includes a **service scaffold** for running Maestral on the host.

1) Install Maestral (recommended with `pipx`):

```bash
sudo apt-get install -y pipx
pipx ensurepath
pipx install maestral
```

2) Link Dropbox (interactive):

```bash
maestral link
```

3) Set Maestral to sync into `/srv/agent/dropbox` (default created by bootstrap):

```bash
maestral config set path /srv/agent/dropbox
```

4) Install the service scaffold (edit USER first):

```bash
sudo cp systemd/maestral.service /etc/systemd/system/maestral.service
sudo $EDITOR /etc/systemd/system/maestral.service
sudo systemctl daemon-reload
sudo systemctl enable --now maestral
```

## Login Portal usage (credential-minimizing)

Goal: you paste credentials + do 2FA **yourself**, then agents use the already-authenticated browser session.

Operational rule:

1) **Pause/stop any agent/browser automation**
2) Open the Login Portal over Tailscale
3) Log in (password manager + 2FA)
4) Close the portal tab
5) Resume automation

The browser profile is persisted at `/srv/agent/browser-profile`.

## Add a new service/port later

If you start something new on the droplet on port `XXXX` and want it reachable over Tailscale only:

```bash
sudo ufw allow in on tailscale0 to any port XXXX proto tcp
```

## Cloud-init (optional)

If you want “paste user-data → droplet boots fully configured”, use:

- `cloud-init/cloud-init.yaml.tmpl`

Replace the placeholders, then paste into DigitalOcean’s **User data** when creating the droplet.

## Troubleshooting

```bash
./scripts/doctor.sh
docker compose ps
docker compose logs -f --tail=200
sudo ufw status verbose
tailscale status
```

## Notes

- This setup prefers simplicity: **no public HTTP exposure**; access is via Tailscale.
- Secrets go in `.env` (gitignored). Never commit it.
