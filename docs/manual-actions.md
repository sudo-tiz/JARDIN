# Manual post-installation steps

Jardin deploys the services, but some settings must still be completed in their web interfaces. Do these steps after `just mash-install-all`, and repeat them if an upgrade or reinstall resets application configuration.

## Nextcloud

Before the first login, run:

```sh
just mash-adjust-nextcloud-config
```

This adjusts URL and trusted-proxy settings. Run it after each Nextcloud version update unless the update was performed with `just mash-upgrade`, which runs this adjustment automatically.

To test email delivery, first set the administrator's email address in their profile, then run the SMTP test in the administration settings.

## Client IPs behind Traefik

Traefik forwards the client address in `X-Forwarded-For`. Each application must trust the proxy before using that address in its logs; otherwise, it sees a private Docker address that Fail2ban ignores.

MASH's Docker network is named `traefik` by default. Find its subnet on the host with:

```sh
docker network inspect traefik --format '{{range .IPAM.Config}}{{println .Subnet}}{{end}}'
```

If `traefik_container_network` was overridden, inspect that network instead. Trust only the proxy address or the required subnet. MASH's shared network includes several containers, so trusting its whole subnet also trusts those containers to assert client IPs. Never use `0.0.0.0/0`.

### Jellyfin

In **Dashboard → Networking → Known Proxies**, add Traefik's address or subnet. Restart Jellyfin if prompted. Also enable **Allow remote connections** if external access is intended. If remote access is disabled, Jellyfin blocks requests before authentication, so Fail2ban's password-failure jail will not count them.

### Seerr

In **Settings → Network**, enable **Enable Proxy Support**. It is disabled by default; enabling it lets Seerr log the client IP forwarded by Traefik. Do not publish Seerr's port directly to the Internet: this setting trusts the proxy headers.

When a user signs in to Seerr with Jellyfin credentials, Jellyfin receives a separate internal request from Seerr and may log Seerr's private IP. The Seerr jail counts that attempt using the public client IP.

### Radarr, Sonarr, Lidarr, and Prowlarr

For each application routed through Traefik, open **Settings → General → Security → Trusted Networks** and add Traefik's address or subnet. Save and restart the application if needed. Keep authentication enabled; do not disable authentication for local addresses to compensate for an untrusted proxy.

In Prowlarr, add indexers under **Settings → Indexers**, then connect the applications under **Settings → Apps**. Before making it publicly reachable, configure authentication; a fresh installation is not protected by an account created by MASH.

After setup, a failed login should appear in the application's log with the public IP. Check the corresponding jail, for example:

```sh
sudo fail2ban-client status jellyfin-auth
sudo fail2ban-client status seerr-auth
```

## qBittorrent

Jardin's current inventory binds the WebUI to `127.0.0.1:8085` and disables Traefik routing. It is not directly reachable from the Internet, so it does not currently need a trusted-proxy setting.

Print the temporary password:

```sh
just mash-run-tags print-password-qbittorrent
```

Open `http://127.0.0.1:8085` on the host, or create an SSH tunnel:

```sh
ssh -L 8085:127.0.0.1:8085 <user>@<host>
```

Sign in as `admin`, then replace the temporary password under **Tools → Options → WebUI → Authentication**. The temporary password may change after a restart.

In Sonarr or Radarr, add qBittorrent as a download client using host `mash-qbittorrent`, internal port `8080`, HTTP without SSL, and the permanent credentials. Ensure download paths are mounted consistently in qBittorrent and the application; otherwise, configure a remote path mapping.

If the WebUI is later routed through Traefik, enable **Enable reverse proxy support** under **Tools → Options → WebUI** and trust only Traefik's address or subnet. Do not apply this step to the current configuration, which does not route qBittorrent through Traefik.
