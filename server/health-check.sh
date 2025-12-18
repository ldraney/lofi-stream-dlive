#!/bin/bash
# Health check script for lofi-stream-dlive
# Run via cron: */5 * * * * /opt/lofi-stream-dlive/health-check.sh

LOG_FILE="/var/log/lofi-dlive-health.log"
SERVICE_NAME="lofi-stream-dlive"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Check if ffmpeg is running for DLive stream
if ! pgrep -f "ffmpeg.*dlive" > /dev/null; then
    log "ERROR: FFmpeg not running for DLive stream"

    # Restart the service
    log "Attempting to restart $SERVICE_NAME..."
    systemctl restart $SERVICE_NAME

    if [ $? -eq 0 ]; then
        log "Service restarted successfully"
    else
        log "ERROR: Failed to restart service"
    fi
else
    log "OK: DLive stream is running"
fi

# Check if Chromium is running
if ! pgrep -f "chromium.*lofi-stream-dlive" > /dev/null; then
    log "WARNING: Chromium not running for DLive - service may need restart"
fi

# Log resource usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
MEM_USAGE=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100)}')
log "Resources: CPU ${CPU_USAGE}%, Memory ${MEM_USAGE}%"

# Check if GitHub Pages is accessible
if curl -s --head "https://ldraney.github.io/lofi-stream-dlive/" | head -n 1 | grep "200\|301\|302" > /dev/null; then
    log "OK: GitHub Pages accessible"
else
    log "WARNING: GitHub Pages may be down"
fi

# Rotate log if too large (> 1MB)
if [ -f "$LOG_FILE" ] && [ $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE") -gt 1048576 ]; then
    mv "$LOG_FILE" "${LOG_FILE}.old"
    log "Log rotated"
fi
