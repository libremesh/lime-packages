
# shared-state-odhcpd\_leases

`shared-state-odhcpd_leases` replaces **dnsmasq** for DHCP in LibreMesh-based firmware. Each node’s **odhcpd** publishes its IPv4 lease table to the Shared‑State CRDT `odhcpd-leases`; peers pull that map, convert remote entries into `/tmp/ethers.mesh`, reload odhcpd and thereby reserve the same addresses mesh‑wide.

## Prerequisites

LibreMesh / OpenWrt with `odhcpd`, `shared-state-async`, `lua`, `luci-lib-jsonc` installed.

Once the package is installed, it will: 

1. register the datatype `odhcpd-leases` in Shared‑State;
2. set `option leasetrigger '/usr/bin/odhcpd-lease-share.sh'` and `option leasefile_static '/tmp/ethers.mesh'` in `/etc/config/dhcp`;
3. symlink `/etc/ethers` → `/tmp/ethers.mesh` when `leasefile_static` is not supported;
4. restarts **odhcpd** and **cron**.

No manual edits are required.

## 1 Quick test (single node)

```sh
# connect a client
ubus call dhcp ipv4leases 
shared-state-async dump odhcpd-leases   # lease visible
cat /tmp/ethers.mesh                    # should see "MAC IP" 
```

## 2 Mesh test (two nodes)

1. Connect client to **Node A** and ensure its lease appears in `dump` on **Node B**.
2. Roam client to **Node B**; `shared-state-async dump odhcpd-leases` and `cat /tmp/ethers.mesh` should show the **same IP**.
3. Connect a second client; confirm addresses never collide.

## Contributing

Open issues or pull requests in the LibreMesh *lime‑packages* repository, including router model, OpenWrt release, logs (`ubus`, `dump`, `/tmp/ethers.mesh`) and reproduction steps.

