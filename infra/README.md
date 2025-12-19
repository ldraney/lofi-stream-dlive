# Infrastructure as Code

Pure Terraform deployment for lofi-stream-dlive on Hetzner Cloud.

## Principles

1. **No manual commands** - Everything via Terraform files
2. **Cloud-init provisioning** - Server configures itself on first boot
3. **Idempotent** - Safe to destroy and recreate
4. **Version controlled** - All config in git (secrets excluded)

## Structure

```
infra/
├── Makefile              # Convenience commands
├── README.md             # This file
└── terraform/
    ├── main.tf           # Provider config
    ├── variables.tf      # Input variables (including secrets)
    ├── server.tf         # CPX22 server + firewall + cloud-init
    ├── outputs.tf        # Server IP, SSH command
    ├── terraform.tfvars  # (gitignored) Secrets
    └── .gitignore        # Excludes state and secrets
```

## What cloud-init does

On first boot, the server automatically:
1. Updates apt and installs packages (xvfb, chromium, ffmpeg, pulseaudio, etc.)
2. Clones the lofi-stream-dlive repo from GitHub
3. Creates systemd service with embedded DLIVE_KEY
4. Enables and starts the stream

## Prerequisites

1. Terraform installed locally
2. SSH key at `~/api-secrets/hetzner-server/id_ed25519`
3. Create `terraform/terraform.tfvars` with:
   ```hcl
   hcloud_token = "your-hetzner-api-token"
   dlive_key    = "your-dlive-stream-key"
   ```

## Usage

```bash
cd infra

# Initialize Terraform (first time only)
make init

# Preview what will be created
make plan

# Create server (includes full provisioning)
make apply

# Wait ~2-3 minutes for cloud-init to complete, then:
make status    # Check if stream is running
make logs      # View stream logs
make ssh       # SSH into server
```

## Server Specs (CPX22)

- 3 dedicated AMD vCPUs
- 4 GB RAM
- 80 GB NVMe SSD
- 20 TB traffic
- Location: Helsinki (hel1)
- Cost: ~$6.99/month

## Monitoring

```bash
make status         # systemctl status
make logs           # journalctl -f
make provision-log  # cloud-init output
```

## Teardown

```bash
make destroy
```

## Updating the stream

To update the stream code:
1. Push changes to GitHub (lofi-stream-dlive repo)
2. SSH in and pull: `make ssh` then `cd /opt/lofi-stream-dlive && git pull`
3. Restart: `systemctl restart lofi-stream-dlive`

Or destroy and recreate (will pull latest code):
```bash
make destroy
make apply
```
