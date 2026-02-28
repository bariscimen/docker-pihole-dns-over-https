<!-- markdownlint-configure-file { "MD004": { "style": "consistent" } } -->
<!-- markdownlint-disable MD033 -->


# Pi-hole with DNS over HTTPS (DoH) using Docker

<p align="center">
    <a href="https://pi-hole.net"><img src="https://pi-hole.github.io/graphics/Vortex/Vortex_with_text.png" height="200" alt="Pi-hole"></a><br/>
    +<br/>DNS over <br/>HTTPS (DoH) <br/> via <strong>dnscrypt-proxy</strong>
</p>

<!-- markdownlint-enable MD033 -->

## Introduction
This project provides a lightweight Docker setup for [Pi-hole](https://github.com/pi-hole/pi-hole) with DNS over HTTPS support via [dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy). It supports x86, AMD64, and ARM architectures.

1) Install docker for your [x86-64 system](https://www.docker.com/community-edition) or [ARM system](https://www.raspberrypi.org/blog/docker-comes-to-raspberry-pi/). [Docker-compose](https://docs.docker.com/compose/install/) is also recommended.
2) Use the above quick start example, customize if desired.
3) Enjoy!

## Quick Start

1. Copy docker-compose.yml.example to docker-compose.yml and update as needed. See example below:
[Docker-compose](https://docs.docker.com/compose/install/) example:

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
      # Set a password to access the web interface. Not setting one will result in a random password being assigned
      FTLCONF_webserver_api_password: 'correct horse battery staple'
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
2. Run `docker compose up -d` to build and start pi-hole (Syntax may be `docker-compose` on older systems)
3. Once Pi-hole is running, you can access the web UI at `http://localhost/admin`. From there, you can change settings, view stats, and more.


## Configuration

The `docker-compose.yml` file contains customizable environment variables:

- `DOH_DNS1` and `DOH_DNS2`: Specify DNS over HTTPS servers. Cloudflare's servers (`https://1.1.1.1/dns-query` and `https://1.0.0.1/dns-query`) are set by default, but you can switch to any other DoH-compatible servers (e.g., Google's `https://8.8.8.8/dns-query`).
- Utilize other [environmental variables from the Docker Pi-Hole project](https://github.com/pi-hole/docker-pi-hole?tab=readme-ov-file#environment-variables) as needed.

## Useful Links

- [Pi-hole Documentation](https://docs.pi-hole.net)
- [Pi-hole GitHub Repository](https://github.com/pi-hole/pi-hole)
- [dnscrypt-proxy GitHub Repository](https://github.com/DNSCrypt/dnscrypt-proxy)
- [dnscrypt-proxy Documentation](https://github.com/DNSCrypt/dnscrypt-proxy/wiki)

## Troubleshooting

If you encounter issues related to Docker, report them on the [GitHub project](https://github.com/bariscimen/docker-pihole-dns-over-https). For Pi-hole or general Docker queries, visit our [user forums](https://discourse.pi-hole.net/c/bugs-problems-issues/docker/30).

## Contributing

Contributions are encouraged! Please create issues for bugs or suggest enhancements. To contribute code, submit a pull request.

## License

This project is licensed under the GNU GPLv3 License.
