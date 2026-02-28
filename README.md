<!-- markdownlint-configure-file { "MD004": { "style": "consistent" } } -->
<!-- markdownlint-disable MD033 -->

# Pi-hole with DNS over HTTPS (DoH)

<p align="center">
    <a href="https://pi-hole.net"><img src="https://pi-hole.github.io/graphics/Vortex/Vortex_with_text.png" height="150" alt="Pi-hole"></a>
    <br/>
    <strong>Pi-hole + DNS over HTTPS</strong><br/>
    powered by <a href="https://github.com/DNSCrypt/dnscrypt-proxy">dnscrypt-proxy</a>
</p>

<!-- markdownlint-enable MD033 -->

A Docker image that runs [Pi-hole](https://pi-hole.net) with built-in DNS over HTTPS (DoH) via [dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy). All DNS queries leaving your network are encrypted — no extra setup required.

**Supported architectures:** `linux/amd64`, `linux/arm64`, `linux/arm/v7`, `linux/arm/v6`, `linux/386`

## Quick Start

1. Create a `docker-compose.yml`:

```yaml
# More info at https://github.com/pi-hole/docker-pi-hole/ and https://docs.pi-hole.net/
services:
  pihole:
    container_name: pihole-dns-over-https
    image: bariscimen/pihole-dns-over-https:latest
    # For DHCP it is recommended to remove these ports and instead add: network_mode: "host"
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "67:67/udp" # Only required if you are using Pi-hole as your DHCP server
      - "80:80/tcp"
    environment:
      # Set the appropriate timezone for your location (https://en.wikipedia.org/wiki/List_of_tz_database_time_zones), e.g:
      TZ: 'Europe/London'
      # Set a password to access the web interface. CHANGE THIS! Not setting one will result in a random password being assigned
      FTLCONF_webserver_api_password: 'correct horse battery staple'  # <-- CHANGE THIS
      # If using Docker's default `bridge` network setting the dns listening mode should be set to 'ALL'
      FTLCONF_dns_listeningMode: 'ALL'
      # DOH_DNS1: 'https://8.8.8.8/dns-query' # Uncomment to use Google DNS over HTTPS instead of Cloudflare
      # DOH_DNS2: 'https://8.8.4.4/dns-query' # Uncomment to use Google DNS over HTTPS instead of Cloudflare
    # Volumes store your data between container upgrades
    volumes:
      - './etc-pihole:/etc/pihole'
      - './etc-dnsmasq.d:/etc/dnsmasq.d'
    #   https://github.com/pi-hole/docker-pi-hole#note-on-capabilities
    cap_add:
      # See https://github.com/pi-hole/docker-pi-hole#note-on-capabilities
      # Required if you are using Pi-hole as your DHCP server, else not needed
      - NET_ADMIN
      # Required if you are using Pi-hole as your NTP client to be able to set the host's system time
      - SYS_TIME
      # Optional, if Pi-hole should get some more processing time
      - SYS_NICE
    restart: unless-stopped
```

2. Run `docker compose up -d`

3. Access the Pi-hole admin UI at **http://localhost/admin**

## How It Works

```
Client → Pi-hole (port 53) → dnscrypt-proxy (port 5053) → DoH upstream (encrypted)
```

Pi-hole handles ad blocking and DNS caching. All upstream queries are forwarded to dnscrypt-proxy, which encrypts them using DNS over HTTPS before sending to the configured upstream servers.

## Configuration

### DoH Upstream Servers

By default, queries are encrypted and sent to Cloudflare's DoH servers:

| Variable   | Default                          |
|------------|----------------------------------|
| `DOH_DNS1` | `https://1.1.1.1/dns-query`     |
| `DOH_DNS2` | `https://1.0.0.1/dns-query`     |

Override these in your `docker-compose.yml` to use a different provider:

```yaml
environment:
  DOH_DNS1: 'https://8.8.8.8/dns-query'       # Google
  DOH_DNS2: 'https://8.8.4.4/dns-query'       # Google
```

### Pi-hole Settings

All [Pi-hole environment variables](https://github.com/pi-hole/docker-pi-hole#environment-variables) are supported. Common ones:

| Variable | Description |
|----------|-------------|
| `TZ` | Timezone ([list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)) |
| `FTLCONF_webserver_api_password` | Admin UI password |
| `FTLCONF_dns_listeningMode` | Set to `ALL` when using Docker's bridge network |

## Troubleshooting

**Verify DoH is working:**

```bash
docker exec pihole-dns-over-https dig @127.0.0.1 -p 5053 cloudflare.com
```

**Check Pi-hole upstream config:**

```bash
docker exec pihole-dns-over-https grep -A3 "upstreams" /etc/pihole/pihole.toml
```

For Docker-related issues, open an issue on the [GitHub project](https://github.com/bariscimen/docker-pihole-dns-over-https). For Pi-hole questions, visit the [Pi-hole forums](https://discourse.pi-hole.net/c/bugs-problems-issues/docker/30).

## Links

- [Pi-hole Documentation](https://docs.pi-hole.net) · [Pi-hole GitHub](https://github.com/pi-hole/pi-hole)
- [dnscrypt-proxy GitHub](https://github.com/DNSCrypt/dnscrypt-proxy) · [dnscrypt-proxy Wiki](https://github.com/DNSCrypt/dnscrypt-proxy/wiki)

## Contributing

Contributions welcome! Open an issue or submit a pull request.

## License

GNU GPLv3
