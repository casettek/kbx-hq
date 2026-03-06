# scripts/

These scripts are intended to be run on the Ubuntu host (the DigitalOcean droplet), usually from
`/opt/kbx-hq`.

## What each script does

- `scripts/bootstrap_ubuntu.sh`
  - Host bootstrap: installs base packages, Docker (+ compose plugin), Tailscale, and creates the
    persistent host directories under `/srv/agent/*`.
  - Must be run as a normal user (not root); it uses `sudo` internally.

- `scripts/install_opencode.sh`
  - Installs the OpenCode CLI on the host using the upstream installer.
  - Idempotent: if `opencode` is already on `PATH`, it exits.

- `scripts/install_filebrowser.sh`
  - Installs File Browser on the host using the upstream installer.
  - Idempotent: if `filebrowser` is already on `PATH`, it exits.

- `scripts/configure_firewall.sh`
  - Configures UFW to deny inbound by default and only allow:
    - SSH
    - Tailscale UDP (41641/udp)
    - App ports on `tailscale0` (defaults: OpenCode + Login Portal)
    - Dev port range `8000-8099` on `tailscale0`
  - Note: this resets UFW rules (`ufw --force reset`).

- `scripts/up.sh`
  - "Bring the box up":
    - Starts `opencode.service` and `filebrowser.service` (if installed)
    - Runs `docker compose up -d` for containers (Caddy + Login Portal)
    - Prints the Tailscale endpoints

- `scripts/doctor.sh`
  - Quick status report: tailscale, ufw, systemd service status, docker compose status, and whether
    `opencode`/`filebrowser` are installed on the host.

- `scripts/ts.sh`
  - Prints Tailscale IP(s) and a reminder of how to access services.

## Related systemd units

See `systemd/*.service` for the host services that `scripts/up.sh` starts:

- `systemd/opencode.service`: runs OpenCode WebUI on the host.
- `systemd/filebrowser.service`: runs File Browser on the host.
- `systemd/maestral.service`: runs Maestral (Dropbox sync) on the host.
