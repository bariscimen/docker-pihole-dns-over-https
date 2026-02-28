#!/bin/bash
set -e

CONFIG_FILE="/etc/dnscrypt-proxy/dnscrypt-proxy.toml"

# Generate a DNS stamp (sdns://) for a DoH server URL
# DNS Stamp format for DoH (protocol 0x02):
#   0x02 | props(8 bytes) | addr_len | addr | hash_len(0) | hostname_len | hostname | path_len | path
generate_stamp() {
    local url="$1"
    local host path addr

    # Parse URL components
    host=$(echo "$url" | sed -E 's|https?://([^/:]+).*|\1|')
    path=$(echo "$url" | sed -E 's|https?://[^/]+(/.+)|\1|')
    # If URL has no explicit path, sed won't match and returns the full URL — default to /dns-query
    case "$path" in
        https://*) path="/dns-query" ;;
    esac

    # Use IP address directly if host is an IP, otherwise leave addr empty
    if echo "$host" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
        addr="$host"
    else
        addr=""
    fi

    # Build binary stamp using printf and pipe to base64
    {
        # Protocol: DoH = 0x02
        printf '\x02'
        # Properties: 8 bytes (DNSSEC=1, No log=1, No filter=1 => 0x07)
        printf '\x07\x00\x00\x00\x00\x00\x00\x00'
        # Address length + address
        printf "\\x$(printf '%02x' ${#addr})"
        [ -n "$addr" ] && printf '%s' "$addr"
        # Hash length (0 = no hash)
        printf '\x00'
        # Hostname length + hostname
        printf "\\x$(printf '%02x' ${#host})"
        printf '%s' "$host"
        # Path length + path
        printf "\\x$(printf '%02x' ${#path})"
        printf '%s' "$path"
    } | base64 | tr -d '\n' | tr '+/' '-_' | sed 's/=*$//'
}

# Default to Cloudflare if neither DOH_DNS var is set
if [ -z "$DOH_DNS1" ] && [ -z "$DOH_DNS2" ]; then
    echo "No DOH_DNS1/DOH_DNS2 set — defaulting to Cloudflare DoH servers"
    DOH_DNS1="https://1.1.1.1/dns-query"
    DOH_DNS2="https://1.0.0.1/dns-query"
fi

echo "Configuring dnscrypt-proxy with DoH servers..."
echo "  DOH_DNS1: ${DOH_DNS1:-not set}"
echo "  DOH_DNS2: ${DOH_DNS2:-not set}"

# Build server names list and static entries
SERVER_NAMES=""
STATIC_BLOCK=""

if [ -n "$DOH_DNS1" ]; then
    STAMP1=$(generate_stamp "$DOH_DNS1")
    SERVER_NAMES="'doh-server-1'"
    STATIC_BLOCK="[static.'doh-server-1']
stamp = 'sdns://${STAMP1}'"
    echo "  Stamp 1: sdns://${STAMP1}"
fi

if [ -n "$DOH_DNS2" ]; then
    STAMP2=$(generate_stamp "$DOH_DNS2")
    if [ -n "$SERVER_NAMES" ]; then
        SERVER_NAMES="${SERVER_NAMES}, 'doh-server-2'"
    else
        SERVER_NAMES="'doh-server-2'"
    fi
    STATIC_BLOCK="${STATIC_BLOCK}
[static.'doh-server-2']
stamp = 'sdns://${STAMP2}'"
    echo "  Stamp 2: sdns://${STAMP2}"
fi

# Update config file
# Remove any existing server_names and static block
sed -i '/^server_names/d' "$CONFIG_FILE"
sed -i '/^\[static\]/,$d' "$CONFIG_FILE"

# Add server_names after listen_addresses (portable — avoids BusyBox sed 'a' quirks)
if [ -n "$SERVER_NAMES" ]; then
    tmp=$(mktemp)
    while IFS= read -r line; do
        printf '%s\n' "$line"
        case "$line" in
            listen_addresses*) printf '%s\n' "server_names = [${SERVER_NAMES}]" ;;
        esac
    done < "$CONFIG_FILE" > "$tmp"
    mv "$tmp" "$CONFIG_FILE"
fi

# Append static block
{
    echo ""
    echo "[static]"
    echo "$STATIC_BLOCK"
} >> "$CONFIG_FILE"

echo "Starting dnscrypt-proxy..."
exec dnscrypt-proxy -config "$CONFIG_FILE"
