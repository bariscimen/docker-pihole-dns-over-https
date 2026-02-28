#!/bin/bash
set -e

PIHOLE_CONFIG="/etc/pihole/pihole.toml"

# Handle shutdown
cleanup() {
    echo "Shutting down services..."
    kill -TERM $DNSCRYPT_PID 2>/dev/null
    kill -TERM $PIHOLE_PID 2>/dev/null
    wait $DNSCRYPT_PID 2>/dev/null
    wait $PIHOLE_PID 2>/dev/null
    exit 0
}
trap cleanup SIGTERM SIGINT

# Start services
echo "Starting dnscrypt-proxy..."
/usr/local/bin/start-dnscrypt-proxy.sh &
DNSCRYPT_PID=$!

echo "Starting Pi-hole..."
/usr/bin/start.sh &
PIHOLE_PID=$!

# Wait for services to be ready
sleep 5

# Verify dnscrypt-proxy is working
if ! dig @127.0.0.1 -p 5053 example.com > /dev/null; then
    echo "Error: dnscrypt-proxy DNS resolution test failed"
    cleanup
    exit 1
fi

# Configure Pi-hole to use dnscrypt-proxy as its upstream DNS
echo "Configuring Pi-hole to use dnscrypt-proxy as upstream DNS..."
# Wait for Pi-hole config file to be created (may take a while on first boot)
for i in $(seq 1 30); do
    [ -f "$PIHOLE_CONFIG" ] && break
    echo "Waiting for $PIHOLE_CONFIG to be created... ($i/30)"
    sleep 1
done
if [ -f "$PIHOLE_CONFIG" ]; then
    sed -i 's/^  upstreams = \[.*\]/  upstreams = [\n    "127.0.0.1#5053"\n  ]/' "$PIHOLE_CONFIG"
    # Signal Pi-hole to reload configuration
    pihole-FTL --config dns.upstreams '["127.0.0.1#5053"]' 2>/dev/null || true
    echo "Pi-hole upstream DNS set to 127.0.0.1#5053 (dnscrypt-proxy)"
else
    echo "Warning: $PIHOLE_CONFIG not found after 30s — Pi-hole upstream DNS not configured"
fi

echo "Services started successfully"

# Monitor processes
while true; do
    if ! kill -0 $DNSCRYPT_PID 2>/dev/null; then
        echo "Error: dnscrypt-proxy exited unexpectedly"
        cleanup
        exit 1
    fi
    if ! kill -0 $PIHOLE_PID 2>/dev/null; then
        echo "Error: Pi-hole exited unexpectedly"
        cleanup
        exit 1
    fi
    sleep 1
done