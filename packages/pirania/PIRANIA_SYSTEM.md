# Pirania system overview

This document explains how Pirania is organized, what each component does, and how the captive-portal flow works in both voucher and read-for-access modes. It is based on the current code under `packages/pirania/`.

## 1. What Pirania is

Pirania is a captive portal for OpenWrt/LibreMesh nodes. It controls Internet access by MAC address and provides two access modes:

- **Voucher mode**: users must enter a voucher code; the voucher is then bound to their device MAC.
- **Read-for-access mode**: users view a portal page and wait a short countdown; their MAC is temporarily authorized.

The authorization list is stored locally and synchronized into nftables rules so that authorized devices bypass the portal.

## 2. High-level architecture

```
Client device
  -> nftables rules (captures DNS/HTTP/HTTPS for unauthorized MACs)
  -> local DNS on port 59053 (pirania-dnsmasq)
  -> local HTTP redirect on port 59080 (pirania-uhttpd)
  -> portal pages on /www/portal/
  -> CGI handlers authorize MAC
  -> captive-portal update (refresh nftables MAC set)
  -> normal Internet access
```

The central behavior is implemented by:

- `packages/pirania/files/usr/bin/captive-portal`
- `packages/pirania/files/etc/init.d/pirania-dnsmasq`
- `packages/pirania/files/etc/init.d/pirania-uhttpd`
- `packages/pirania/files/www/pirania-redirect/redirect`
- `packages/pirania/files/usr/lib/lua/portal/portal.lua`

## 3. Configuration (UCI)

The main configuration file is `packages/pirania/files/etc/config/pirania`.

Key options in `base_config`:

- `enabled`: whether the portal is active at boot
- `with_vouchers`: toggle voucher vs read-for-access mode
- `portal_domain`: domain used for portal URLs (default `thisnode.info`)
- `url_auth`, `url_authenticated`, `url_info`, `url_fail`: portal page paths
- `db_path`: voucher database directory (JSON files)
- `hooks_path`: directory for hook scripts (e.g., shared-state sync)
- `allowlist_ipv4`, `allowlist_ipv6`: ranges that bypass the captive portal

Access-mode options live in `config access_mode 'read_for_access'`:

- `url_portal`: path to the read-for-access page
- `duration_m`: authorization duration in minutes

## 4. Services and startup

- `packages/pirania/files/etc/init.d/pirania` starts the portal if enabled and runs hooks.
- `packages/pirania/files/etc/init.d/pirania-dnsmasq` runs a dedicated dnsmasq on port 59053.
- `packages/pirania/files/etc/init.d/pirania-uhttpd` runs a small uhttpd on port 59080.
- `packages/pirania/files/etc/uci-defaults/90-captive-portal-cron` installs a cron job to refresh nftables every 10 minutes.

## 5. Traffic capture (nftables)

`packages/pirania/files/usr/bin/captive-portal` sets up nftables rules in the `inet pirania` table:

- Creates sets for authorized MACs (`pirania-auth-macs`) and allowlisted IPv4/IPv6 ranges.
- Redirects DNS (UDP/53) to port 59053 for unauthorized MACs.
- Redirects HTTP (TCP/80) to port 59080 for unauthorized MACs.
- Drops HTTPS (TCP/443) for unauthorized MACs.
- Allows traffic for MACs in `pirania-auth-macs` and destinations in the allowlist sets.

Authorized MACs come from `packages/pirania/files/usr/bin/pirania_authorized_macs`, which delegates to the Lua portal library and returns either voucher-based or read-for-access MACs.

## 6. DNS hijack

`packages/pirania/files/etc/init.d/pirania-dnsmasq` starts a dnsmasq instance that:

- Answers `thisnode.info` with the node IP.
- Uses shared-state hosts from `/var/hosts/shared-state-dnsmasq_hosts`.
- Sends unknown domains to a fallback IP (1.2.3.4).

This ensures the portal domain resolves locally when the user is captured.

## 7. HTTP redirect service

`packages/pirania/files/etc/init.d/pirania-uhttpd` starts an HTTP server on port 59080 serving `packages/pirania/files/www/pirania-redirect/redirect`.

The redirect script:

- Builds a `prev` URL from the original request.
- Picks the portal entry point based on `with_vouchers`:
  - Voucher mode: `base_config.url_auth`
  - Read-for-access mode: `read_for_access.url_portal`
- Sends a 302 redirect to `http://<portal_domain><path>?prev=<original>`.

## 8. Portal pages and assets

Static portal pages are under `packages/pirania/files/www/portal/`:

- `auth.html` (voucher entry)
- `info.html` (waiting/info screen)
- `authenticated.html` (success)
- `fail.html` (error)
- `read_for_access.html` (non-voucher flow)

Portal content (title, text, logo, colors) is stored in `packages/pirania/files/etc/pirania/portal.json`. The Lua module `packages/pirania/files/usr/lib/lua/portal/portal.lua` can read/write this content and also synchronize it via shared-state (`pirania_persistent`).

## 9. Voucher subsystem

Voucher logic is implemented in `packages/pirania/files/usr/lib/lua/voucher/` and exposed via the CLI `packages/pirania/files/usr/bin/voucher`.

Key files:

- `vouchera.lua`: main voucher model and operations (create, activate, invalidate, list, status checks).
- `store.lua`: JSON file storage (`db_path/<id>.json`).
- `config.lua`: reads `db_path`, `hooks_path`, pruning settings.
- `hooks.lua`: executes hook scripts under `hooks_path/<action>/` on database changes.
- `utils.lua`: URL parsing and IP/MAC lookup via ARP/neigh tables.

Voucher lifecycle:

1. **Create**: `voucher add` calls `vouchera.create`, which writes a JSON file and triggers `hooks.run('db_change')`.
2. **Activate**: voucher code is bound to a MAC and `captive-portal update` refreshes nftables.
3. **Invalidate**: sets `invalidation_date`, keeping the record for pruning; also refreshes nftables if needed.
4. **Prune**: old expired/invalidated vouchers are removed when `vouchera.init()` runs.

The CLI wraps these operations in `packages/pirania/files/usr/bin/voucher`.

## 10. Read-for-access subsystem

Read-for-access mode uses:

- `packages/pirania/files/usr/lib/lua/read_for_access/read_for_access.lua`
- `packages/pirania/files/usr/lib/lua/read_for_access/cgi_handlers.lua`

MACs are stored in `/tmp/pirania/read_for_access/auth_macs` with an expiration timestamp (based on system uptime). When a user completes the portal wait, their MAC is added and `captive-portal update` refreshes nftables.

## 11. CGI endpoints

Portal pages call CGI scripts under `packages/pirania/files/www/cgi-bin/pirania/`:

- `preactivate_voucher`: validates voucher and either redirects to `info.html` (JS flow) or activates immediately (no-JS flow).
- `activate_voucher`: final activation endpoint, binds voucher to MAC.
- `authorize_mac`: used by read-for-access to authorize a MAC for a limited time.
- `client_ip`: legacy endpoint that references old modules and is not used by current voucher flow.

## 12. Ubus/rpcd API

The ubus service is implemented in `packages/pirania/files/usr/libexec/rpcd/pirania` and exposed via ACLs in `packages/pirania/files/usr/share/rpcd/acl.d/pirania.json`.

Supported calls include:

- `get_portal_config`, `set_portal_config`
- `add_vouchers`, `list_vouchers`, `invalidate`, `rename`
- `get_portal_page_content`, `set_portal_page_content`

These are consumed by Lime-App or other management tools.

## 13. Tests

Pirania tests live under `packages/pirania/tests/` and cover portal flows, voucher logic, rpcd handlers, and CGI helpers.

## 14. End-to-end flow summary

Voucher mode:

1. User hits an external site; DNS/HTTP are redirected to Pirania.
2. User lands on `auth.html` and submits a voucher code.
3. `preactivate_voucher` checks the code; if valid, the user waits on `info.html` (JS flow) and then calls `activate_voucher`.
4. Voucher binds to MAC and nftables set is refreshed.
5. User is redirected to the original URL or `authenticated.html`.

Read-for-access mode:

1. User hits an external site; DNS/HTTP are redirected to Pirania.
2. User lands on `read_for_access.html` and waits the countdown.
3. `authorize_mac` stores the MAC with a short TTL and refreshes nftables.
4. User is redirected to the original URL or `authenticated.html`.

## 15. Notes and caveats

- The current implementation uses **nftables** (not iptables) via `captive-portal`.
- `catch_interfaces`/`catch_bridged_interfaces` are present in UCI config but are not currently applied to nftables rules.
- The `client_ip` CGI script appears to depend on legacy modules (`voucher.logic`, `voucher.db`).

---

If you want, I can add a short “operator guide” section (common commands, troubleshooting, or a flow diagram) based on how you deploy Pirania.
