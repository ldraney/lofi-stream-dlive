# SSH Key - use existing shared key
data "hcloud_ssh_key" "main" {
  name = "lofi-streams"
}

# DLive Stream Server
resource "hcloud_server" "dlive" {
  name        = "lofi-dlive"
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys    = [data.hcloud_ssh_key.main.id]

  labels = {
    project  = "lofi-stream"
    platform = "dlive"
    theme    = "space_station"
  }

  # Cloud-init: full provisioning on first boot
  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > /var/log/cloud-init-lofi.log 2>&1

    echo "=== Starting lofi-stream-dlive provisioning ==="

    # Update system
    apt-get update
    apt-get upgrade -y

    # Install required packages
    apt-get install -y \
      xvfb \
      pulseaudio \
      ffmpeg \
      xdotool \
      chromium-browser \
      git \
      curl \
      htop

    # Clone stream repository
    echo "=== Cloning repository ==="
    git clone https://github.com/ldraney/lofi-stream-dlive.git /opt/lofi-stream-dlive

    # Make scripts executable
    chmod +x /opt/lofi-stream-dlive/server/*.sh

    # Create systemd service with stream key
    echo "=== Creating systemd service ==="
    cat > /etc/systemd/system/lofi-stream-dlive.service <<'SYSTEMD'
    [Unit]
    Description=Lofi Stream to DLive (Space Station Theme)
    After=network.target

    [Service]
    Type=simple
    User=root
    WorkingDirectory=/opt/lofi-stream-dlive/server
    Environment=DLIVE_KEY=${var.dlive_key}
    ExecStart=/opt/lofi-stream-dlive/server/stream.sh
    Restart=always
    RestartSec=10
    StandardOutput=journal
    StandardError=journal

    [Install]
    WantedBy=multi-user.target
    SYSTEMD

    # Enable and start service
    echo "=== Starting stream service ==="
    systemctl daemon-reload
    systemctl enable lofi-stream-dlive
    systemctl start lofi-stream-dlive

    echo "=== Provisioning complete ==="
  EOF
}

# Firewall - SSH only (RTMP is outbound)
resource "hcloud_firewall" "dlive" {
  name = "lofi-dlive-firewall"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_firewall_attachment" "dlive" {
  firewall_id = hcloud_firewall.dlive.id
  server_ids  = [hcloud_server.dlive.id]
}
