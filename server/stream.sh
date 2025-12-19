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

# Cleanup any existing processes (but not PulseAudio)
cleanup() {
    echo "Cleaning up..."
    pkill -f "Xvfb :$DISPLAY_NUM" 2>/dev/null || true
    pkill -f "chromium.*lofi-stream-dlive" 2>/dev/null || true
    pkill -f "ffmpeg.*dlive" 2>/dev/null || true
}

trap cleanup EXIT
cleanup
sleep 2

# Start virtual display
echo "=== Starting virtual display :$DISPLAY_NUM ==="
Xvfb :$DISPLAY_NUM -screen 0 ${RESOLUTION}x24 &
sleep 3
export DISPLAY=:$DISPLAY_NUM

# PulseAudio setup
echo "=== Setting up PulseAudio ==="
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# Start PulseAudio if not running
if ! pulseaudio --check 2>/dev/null; then
    echo "Starting PulseAudio..."
    pulseaudio --start --exit-idle-time=-1
    sleep 3
fi

# Wait for PulseAudio to be ready
echo "Waiting for PulseAudio..."
for i in {1..15}; do
    if pactl info >/dev/null 2>&1; then
        echo "PulseAudio is ready"
        break
    fi
    echo "  waiting... ($i)"
    sleep 1
done

# Create virtual audio sink if it doesn't exist
if ! pactl list sinks short 2>/dev/null | grep -q "$SINK_NAME"; then
    echo "Creating audio sink: $SINK_NAME"
    pactl load-module module-null-sink sink_name=$SINK_NAME sink_properties=device.description=VirtualSpeaker || true
    sleep 1
fi

# Set as default sink
pactl set-default-sink $SINK_NAME 2>/dev/null || true

# Show current audio setup
echo "Audio sinks:"
pactl list sinks short 2>/dev/null || echo "  (could not list sinks)"

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

# Route any audio to our sink
echo "Routing audio to $SINK_NAME..."
for input in $(pactl list sink-inputs short 2>/dev/null | cut -f1); do
    pactl move-sink-input "$input" "$SINK_NAME" 2>/dev/null && echo "  routed input $input" || true
done

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
