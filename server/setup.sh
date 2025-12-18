#!/bin/bash
# Setup script for lofi-stream-dlive on VPS

set -e

echo "Setting up lofi-stream-dlive..."

# Install dependencies
echo "Installing dependencies..."
apt-get update
apt-get install -y xvfb chromium-browser ffmpeg pulseaudio xdotool curl jq

# Create directory
echo "Creating /opt/lofi-stream-dlive..."
mkdir -p /opt/lofi-stream-dlive

# Copy scripts
echo "Copying scripts..."
cp stream.sh /opt/lofi-stream-dlive/
cp health-check.sh /opt/lofi-stream-dlive/
chmod +x /opt/lofi-stream-dlive/*.sh

# Install systemd service
echo "Installing systemd service..."
cp lofi-stream-dlive.service /etc/systemd/system/
systemctl daemon-reload

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit /etc/systemd/system/lofi-stream-dlive.service"
echo "   Change: Environment=DLIVE_KEY=YOUR_STREAM_KEY_HERE"
echo ""
echo "2. Get your DLive stream key from:"
echo "   https://dlive.tv -> Dashboard -> Stream Settings"
echo ""
echo "3. Enable and start the service:"
echo "   systemctl enable lofi-stream-dlive"
echo "   systemctl start lofi-stream-dlive"
echo ""
echo "4. Check status:"
echo "   systemctl status lofi-stream-dlive"
echo "   journalctl -u lofi-stream-dlive -f"
