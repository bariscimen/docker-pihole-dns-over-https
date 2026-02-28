FROM pihole/pihole

# Expose required ports
EXPOSE 53/tcp 53/udp 67/udp 80/tcp 443/tcp

# Default DoH upstream servers (can be overridden via environment variables)
ENV DOH_DNS1=https://1.1.1.1/dns-query
ENV DOH_DNS2=https://1.0.0.1/dns-query

# Install dnscrypt-proxy and bash
RUN apk add --no-cache dnscrypt-proxy bash bind-tools

# Copy scripts and config template
COPY dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml
COPY scripts/start-dnscrypt-proxy.sh /usr/local/bin/
COPY scripts/custom-entrypoint.sh /usr/local/bin/

# Make scripts executable
RUN chmod +x /usr/local/bin/start-dnscrypt-proxy.sh \
    && chmod +x /usr/local/bin/custom-entrypoint.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD dig @127.0.0.1 -p 5053 cloudflare.com || exit 1

ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]