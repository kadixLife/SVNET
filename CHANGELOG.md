# Changelog

## 1.0.0-alpha.1 - 2026-07-04

- Project renamed to MikroTik_VPN.
- Removed GUI Admin Panel, Docker, Next.js, backend API, PostgreSQL, nginx access flow, setup wizard and setup token flow.
- Focused the project on VPS + MikroTik VPN automation through a CLI-only manager.
- Added `mikrotik-vpn` as the primary command and kept `svnet` only as a temporary compatibility alias.
- Changed production paths to `/opt/mikrotik-vpn`, `/opt/mikrotik-vpn/repo`, `/opt/mikrotik-vpn/output`, `/opt/mikrotik-vpn/backups` and `/usr/local/bin/mikrotik-vpn`.
- Kept OpenVPN UDP MVP, MikroTik `.ovpn` generation, RouterOS `.rsc` generation, VPN-first split routing, RU direct lists, VPN force lists, local bypass, DNS redirect, MSS clamp, health checks, backup/update logic and safe temporary HTTP publish.
- Added `mikrotik-vpn-update-lists.rsc` for updating MikroTik routing lists separately from first install.
- Updated menus and docs for simple CLI-only operation.

Previous stable SVNET base remains available in Git tag `v1.0.4`.
