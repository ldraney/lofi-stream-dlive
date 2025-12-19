#!/bin/bash
# Lofi Stream to DLive
# Captures a headless browser playing our space station lofi page and streams to DLive
# Simplified for single-server deployment

set -e

# Configuration
DISPLAY_NUM=95
SINK_NAME="virtual_speaker"
RESOLUTION="1280x720"
FPS=30
DLIVE_URL="rtmp://stream.dlive.tv/live"
PAGE_URL="https://ldraney.github.io/lofi-stream-dlive/"

# Stream key from environment
if [ -z "$DLIVE_KEY" ]; then
    echo "Error: DLIVE_KEY environment variable not set"
    exit 1
fi

echo "=== Starting Lofi Stream to DLive ==="
echo "Resolution: $RESOLUTION @ ${FPS}fps"
echo "Sink: $SINK_NAME"

# Cleanup any existing processes
cleanup() {
    echo "Cleaning up..."
    pkill -f "Xvfb :$DISPLAY_NUM" 2>/dev/null || true
    pkill -f "chromium.*lofi-stream-dlive" 2>/dev/null || true
    pkill -f "ffmpeg.*dlive" 2>/dev/null || true
    pulseaudio --kill 2>/dev/null || true
}

trap cleanup EXIT
cleanup
sleep 2

# Start virtual display
echo "=== Starting virtual display :$DISPLAY_NUM ==="
Xvfb :$DISPLAY_NUM -screen 0 ${RESOLUTION}x24 &
sleep 3
export DISPLAY=:$DISPLAY_NUM

# PulseAudio setup - simplified for single server
echo "=== Setting up PulseAudio ==="
export XDG_RUNTIME_DIR=/run/user/0
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# Kill any existing pulseaudio and start fresh
pulseaudio --kill 2>/dev/null || true
sleep 1

# Start PulseAudio in background with autospawn disabled
pulseaudio --start --exit-idle-time=-1 --daemonize=yes 2>/dev/null || true
sleep 2

# Wait for PulseAudio to be ready
echo "Waiting for PulseAudio..."
for i in {1..10}; do
    if pactl info >/dev/null 2>&1; then
        echo "PulseAudio is ready"
        break
    fi
    sleep 1
done

# Create virtual audio sink
echo "Creating audio sink: $SINK_NAME"
pactl load-module module-null-sink sink_name=$SINK_NAME sink_properties=device.description=VirtualSpeaker 2>/dev/null || true
sleep 1

# Verify sink was created
if pactl list sinks short | grep -q "$SINK_NAME"; then
    echo "Audio sink created successfully"
else
    echo "Warning: Could not verify sink creation, continuing anyway..."
fi

# Set as default sink
pactl set-default-sink $SINK_NAME 2>/dev/null || true

# Start Chromium
echo "=== Starting Chromium ==="
PULSE_SINK=$SINK_NAME chromium-browser \
    --no-sandbox \
    --disable-gpu \
    --disable-software-rasterizer \
    --disable-dev-shm-usage \
    --user-data-dir=/tmp/chromium-dlive \
    --kiosk \
    --autoplay-policy=no-user-gesture-required \
    --window-size=1280,720 \
    --window-position=0,0 \
    "$PAGE_URL" &
CHROME_PID=$!

# Wait for page to load
echo "Waiting for page to load..."
sleep 10

# Trigger audio with xdotool
echo "Triggering audio playback..."
xdotool mousemove 640 360 click 1
sleep 1
xdotool key space
sleep 1
xdotool mousemove 640 360 click 1
sleep 3

# Route any Chromium audio to our sink
echo "Routing audio..."
for input in $(pactl list sink-inputs short 2>/dev/null | cut -f1); do
    pactl move-sink-input "$input" "$SINK_NAME" 2>/dev/null || true
done

# Verify we have the monitor source
echo "=== Verifying audio setup ==="
pactl list sources short
echo ""

# Start FFmpeg streaming to DLive
echo "=== Starting FFmpeg stream to DLive ==="
ffmpeg \
    -thread_queue_size 1024 \
    -f x11grab \
    -video_size $RESOLUTION \
    -framerate $FPS \
    -draw_mouse 0 \
    -i :$DISPLAY_NUM \
    -thread_queue_size 1024 \
    -f pulse \
    -i ${SINK_NAME}.monitor \
    -c:v libx264 \
    -preset ultrafast \
    -tune zerolatency \
    -b:v 4500k \
    -maxrate 4500k \
    -bufsize 9000k \
    -pix_fmt yuv420p \
    -g 60 \
    -c:a aac \
    -b:a 160k \
    -ar 44100 \
    -flvflags no_duration_filesize \
    -f flv "${DLIVE_URL}/${DLIVE_KEY}"
