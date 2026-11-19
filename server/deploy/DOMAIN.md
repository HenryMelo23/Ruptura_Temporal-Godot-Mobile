# rupturatemporal.cloud

Dedicated Nginx virtual host for the Ruptura relay on `127.0.0.1:8090`.
Never replace `default`, `mecurso`, or other projects' configurations.
The HTTP and HTTPS files are alternatives, not simultaneously enabled.

## DNS at Hostinger

| Type | Name | Value |
| --- | --- | --- |
| A | @ | 72.61.217.238 |
| CNAME | www | rupturatemporal.cloud |

Keep nameservers and unrelated records, including mail, intact. Do not add AAAA
unless IPv6 on the VPS has been configured and verified. Existing CAA must allow
the chosen certificate authority.

## Activation sequence

1. Back up existing Nginx site files; record their hashes and service PIDs.
2. Install the HTTP-only file as
   `/etc/nginx/sites-available/rupturatemporal.cloud`, enable that exact site,
   run `nginx -t`, and reload Nginx (do not restart existing applications).
3. Test using `curl --resolve rupturatemporal.cloud:80:72.61.217.238
   http://rupturatemporal.cloud/leaderboard` before DNS propagation.
4. Verify authoritative/public DNS for apex and www. Both must resolve to this VPS.
5. Obtain a Let's Encrypt certificate with the webroot authenticator, using
   `/opt/ruptura/acme-webroot`. Keep ACME config, work and logs isolated under
   `/opt/ruptura/acme-config`, `/opt/ruptura/acme-work`, `/opt/ruptura/acme-logs`.
   An official `certbot/certbot` image pinned by digest avoids system Python or
   other projects' package changes. Mount these exact directories into the
   container at identical paths; do not use standalone validation or stop Nginx.
6. Only after the certificate exists, install the HTTPS template, syntax-test,
   and reload. It redirects HTTP and www to the canonical HTTPS apex and `/`
   to `/leaderboard`. Do not enable HSTS until the complete domain is verified.
7. Configure a Ruptura-specific renewal timer, test renewal, and reload Nginx only
   when a valid renewed certificate is available. Do not modify other renewals.
8. Check certificate chain/SAN/expiry, redirects, ranking, Umbra, assets and health
   publicly, plus unchanged hashes/status for other sites and applications.

The IP/port URL remains available to existing clients. This setup does not change
the game's relay address, update manifests, public download URL generator or UDP
multiplayer transport. Moving those client-facing contracts is a separate change.

## Verified activation (2026-10-27)

- Both authoritative nameservers and public resolvers resolve apex to
  `72.61.217.238`; www is a CNAME to the apex.
- HTTPS active with Let's Encrypt certificate covering apex and www;
  initial certificate expires 2027-01-25. Public TLS validation returned 0.
- HTTP and www redirect to canonical HTTPS; `/` opens `/leaderboard`.
- Ranking, Umbra, images and health verified on the public domain. Browser
  checks passed at 1440x1000, 390x844 and 844x390, without page errors/overflow.
- `/leaderboard/downloads` exposes the current Windows, Linux and Android
  manifests through same-origin HTTPS links. Large binaries remain streamed by
  the relay with byte ranges; the domain proxy must preserve range headers.
- `ruptura-certbot.timer` enabled with two daily checks and randomized delay.
  Certificate renewal dry-run passed; renewal service returned exit status 0.
  The pinned image version at activation was Certbot 5.8.0.
- Nginx syntax valid; default/mecurso hashes unchanged; Nginx master, relay,
  Docker and MediaMTX PIDs unchanged. Only a graceful Nginx reload was needed.
- Prior HTTP config backup:
  `/opt/ruptura/release-backups/domain-tls-20261027T121259Z/http.conf`.
- Umbra historical baseline remains `2026-10-27T11:29:48.503Z`.

Renewal uses the dedicated script/service/timer beside this document. A successful
renewal changes the certificate hash, then syntax-tests and gracefully reloads
Nginx. With no certificate change, no reload occurs. Private keys and ACME account
files stay on the VPS; never copy them into the repository.
