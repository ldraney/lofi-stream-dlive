# lofi-stream-dlive

24/7 lofi stream to DLive with a space station theme.

## Secrets

```bash
# Stream key and RTMP URL
cat ~/api-secrets/lofi-stream/platforms/dlive.env

# SSH key for servers
~/api-secrets/hetzner-server/id_ed25519
```

## Quick Reference

```bash
# Local development - open in browser
cd docs && python3 -m http.server 8080

# Deploy to dev server for testing
make deploy-dev

# Check production status
ssh root@135.181.150.82 'systemctl status lofi-stream-dlive'
```

## Architecture

```
GitHub Pages (static HTML/CSS/JS)
        ↓ (rendered by)
Chromium on Hetzner VPS (:95)
        ↓ (captured by)
FFmpeg → RTMP → DLive
```

## Theme: Space Station

Visual elements:
- Deep space background with layered twinkling stars
- Orbital space station viewport showing Earth below
- Aurora effect visible through the window
- Orbiting satellite in the viewport
- Control panel with indicators and audio waveform display
- Solar panels extending from station arms

Color palette:
- Deep blue space: #000510, #0a1628
- Earth blue: #4a9fff, #2a6fdf
- Aurora green: #00ffaa
- Control cyan: #00aaff
- Panel orange: #ff6600

## Audio: Space Ambient Lofi

- Layered sine wave drones at sub-bass through octave frequencies
- Ethereal major 7th chord pads with slow attack/release
- Gentle bell-like satellite ping sounds
- Subtle white noise for space static
- Occasional low frequency rumble (station vibration)
- Slow LFO modulation on all elements

## Server Configuration

| Setting | Value |
|---------|-------|
| Display | :95 |
| Audio Sink | dlive_speaker |
| User Data Dir | /tmp/chromium-dlive |
| RTMP URL | rtmp://stream.dlive.tv/live |
| Video Bitrate | 4500 kbps |
| Audio Bitrate | 160 kbps |
| Resolution | 1280x720 @ 30fps |

## File Structure

```
lofi-stream-dlive/
├── CLAUDE.md           # This file
├── README.md           # Public readme
├── Makefile            # Dev server deployment
├── docs/
│   ├── index.html      # Space station visuals + Web Audio
│   └── style.css       # Deep space styling
└── server/
    ├── stream.sh       # Main streaming script
    ├── setup.sh        # Server setup automation
    ├── health-check.sh # Monitoring script
    └── lofi-stream-dlive.service # systemd unit
```

## Deployment

### First-time setup on production server:

```bash
# On VPS (135.181.150.82)
cd /opt
git clone https://github.com/ldraney/lofi-stream-dlive.git
cd lofi-stream-dlive/server
chmod +x *.sh
./setup.sh

# Edit service file to add stream key
sudo nano /etc/systemd/system/lofi-stream-dlive.service
# Change: Environment=DLIVE_KEY=YOUR_STREAM_KEY_HERE

# Start the service
sudo systemctl daemon-reload
sudo systemctl enable lofi-stream-dlive
sudo systemctl start lofi-stream-dlive
```

### Get DLive Stream Key:

1. Go to https://dlive.tv
2. Dashboard > Stream Settings
3. Copy the Stream Key

## DLive Platform Notes

- Revenue split: 90/10 (in your favor!)
- Currency: LINO points (crypto-based)
- 24/7 streaming: Fully supported
- Audience: Crypto-friendly, loyal community

## Troubleshooting

### No audio in stream
- Check if PulseAudio sink exists: `pactl list sinks | grep dlive`
- Verify Chromium audio routing: `pactl list sink-inputs`
- Ensure PULSE_SERVER is exported in stream.sh

### Stream not connecting
- DLive uses standard RTMP (not RTMPS)
- Verify stream key is correct
- Check DLive dashboard for any account issues

### Video quality issues
- DLive supports up to 6000 kbps - can increase if needed
- Check CPU usage: `htop`
- Verify ffmpeg is using hardware acceleration if available

## Related Repos

- [lofi-stream-youtube](https://github.com/ldraney/lofi-stream-youtube) - Night city theme
- [lofi-stream-twitch](https://github.com/ldraney/lofi-stream-twitch) - Coffee shop theme
- [lofi-stream-kick](https://github.com/ldraney/lofi-stream-kick) - Arcade theme
- [lofi-stream-odysee](https://github.com/ldraney/lofi-stream-odysee) - Underwater theme
- [lofi-stream-docs](https://github.com/ldraney/lofi-stream-docs) - Documentation hub
