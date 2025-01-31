# Discoverable Services
 
## What

Exposes a `name`, `description`, `icon` and `ui` (port and path) for each service which had `APP_NAME`, `APP_DESCRIPTION`, `APP_ICON`, `APP_UI` addded to their [Balena environments]().

Should also accept other formats for Docker, docker-compose or native server setups, according to a manifest format.

## Architecture

1. Check connect clients on `/tmp/dhcp.leases`
1. For each client do `wget` on port `48484`
1. If json reponse, save it to `/tmp/services/{ip}.json`
1. Parse json and save a pruned version to `/www/cgi-bin/services`
1. Lime-App or other community-portals can easily fetch services data from `thisnode.info/www/cgi-bin/services`

## Opinions
- [Balena](https://balena.io) will be highly encouraged because:
  - [Balena Hub](https://hub.balena.io/) has a growing number of out-of-the-box apps
  - [Balena Cloud](https://balena-cloud.com) is free as long as project is published and used from Balena Hub
  - simple migration from existing docker/docker-compose stack
  - lightweight container-based operating system
  - support for various types of single-board-computers and architectures
  - over-the-air-updates
  - small self-updating images
  - per-device release pinning
  - bulk monitoring of all devices and their services
  - remote access to all devices and services via web terminal
  - ssh tunnel & remote support
- Other docker stacks can work by adding an additional thin httpd image exposing the services manifest
- Native stacks can work by exposing services manifest

## Challenges

- Offline
  - [Balena offline updates](https://www.balena.io/blog/offline-updates-make-it-easier-to-update-balena-devices-without-the-internet/)