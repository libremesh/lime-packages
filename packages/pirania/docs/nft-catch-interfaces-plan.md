# Plan: Implement catch_interfaces and catch_bridged_interfaces (nftables)

## Goals

- Scope Pirania to explicitly configured ingress interfaces only.
- Stop captive-portal from affecting mesh interfaces by default.
- Keep behavior aligned with the legacy iptables+ebtables model.
- Minimize structural changes to current nftables script.

## Constraints / Fit

- Keep the dedicated `inet pirania` table (no fw4 refactor).
- Use interface-name matching (stable for dynamic devices).
- Preserve existing Tranca/allowlist logic and rule ordering.

## Operator Guidance (names + defaults)

- **Values are ifnames**, not UCI network names. Use `ip link` and `bridge link`
  to confirm actual interface names (e.g. `br-lan`, `wlan0-ap`, `bat0`).
- **Default behavior** should be safe: if both lists are empty, portal should
  catch nothing (avoid blocking mesh/infrastructure).
- In mesh deployments, **avoid** catching mesh/backbone interfaces (`bat0`,
  `mesh0`, `wlan0-mesh`, etc) unless explicitly desired.
- Typical default: `catch_bridged_interfaces` contains AP ifnames; `catch_interfaces`
  contains the bridge (`br-lan`) only if you _intend_ to portal all LAN traffic.

## UCI Schema Changes

The default config (`/etc/config/pirania`) must include `catch_bridged_interfaces`;
`catch_interfaces` is optional and intentionally commented out in the mesh-safe default.

**Current state** (problematic - catches mesh via br-lan):

```
list catch_interfaces 'br-lan'
```

**New default** for `packages/pirania/files/etc/config/pirania`:

```
# Interface catch lists (ifnames, not UCI network names)
# catch_interfaces: L3 interfaces for direct nftables matching
# catch_bridged_interfaces: L2 bridged interfaces for bridge-family marking
#
# MESH-SAFE DEFAULT: Only catch Wi-Fi AP interfaces, not br-lan.
# br-lan typically includes bat0 (mesh backbone) which must NOT be caught.
# Uncomment catch_interfaces only if you explicitly want to portal wired LAN
# or understand that br-lan may include mesh interfaces.
#
# list catch_interfaces 'br-lan'
list catch_bridged_interfaces 'wlan0-ap'
```

**Rationale**: On LibreMesh, `br-lan` contains `bat0` (the mesh backbone).
Catching `br-lan` would block mesh traffic, breaking the network. The safe
default catches only Wi-Fi AP interfaces at L2 (bridge family), leaving
mesh and wired infrastructure unaffected.

**Migration note**: Existing deployments with sysupgrade retain their config.
Operators should:

1. Remove or comment out `list catch_interfaces 'br-lan'`
2. Add `list catch_bridged_interfaces 'wlan0-ap'` (adjust ifname as needed)

**Optional: Catching wired LAN clients**

If wired LAN clients should also go through the portal (and mesh is on a
separate interface or VLAN), operators can uncomment `catch_interfaces`:

```
list catch_interfaces 'br-lan'
list catch_bridged_interfaces 'wlan0-ap'
```

**Warning**: Only do this if you've verified `br-lan` does not include mesh
interfaces, or if you explicitly want to portal all bridge traffic.

## Best-practice notes (nftables/OpenWrt)

- Prefer `iifname` (ifname type) for dynamic interfaces; avoid `iif` for devices
  that may be created/destroyed (ppp, tun/tap, veth, etc).
- Use `type ifname` sets for interface lists.
- Use base-chain priorities via keywords where possible (e.g. `dstnat`, `filter`).
- **NAT base chains** must use priority `> -200` (conntrack runs at -200).
- **Bridge family prerouting** can use `dstnat` priority (`-300`) to run early.
- OpenWrt supports nftables drop-ins in `/usr/share/nftables.d/` (packages)
  and `/etc/nftables.d/` (admin), but we keep the existing script to avoid
  refactoring across fw4.

## Dependencies (bridge-family nftables)

The L2 marking via `table bridge pirania` requires bridge-family nftables support:

- **Kernel**: `CONFIG_NFT_BRIDGE` must be enabled
- **OpenWrt package**: `kmod-nft-bridge`

**Package Makefile change** (`packages/pirania/Makefile`):

```makefile
DEPENDS:=... +kmod-nft-bridge
```

**Implementation should verify** bridge family is available at runtime:

```sh
if ! nft list tables bridge >/dev/null 2>&1; then
    echo "Error: bridge-family nftables not available (missing kmod-nft-bridge?)"
    exit 1
fi
```

**Fallback behavior**: If bridge-family is unavailable, the entire
`catch_bridged_interfaces` mechanism breaks. Recommended behavior is to
fail hard with a clear error rather than silently degrading - silent
degradation could lead to unexpected portal behavior (e.g., catching
nothing, or catching everything via a misconfigured `catch_interfaces`).

Hard-fail is safer than silent failure; operators must either install
`kmod-nft-bridge` or remove `catch_bridged_interfaces` from the config
and use `catch_interfaces` instead (L3-only mode, with the mesh-safety
caveats noted in the UCI section).

## Proposed Design

1. **Interface sets (name-based)**
   - Add nft sets for interface names:
     - `inet pirania pirania-catch-ifaces` (type `ifname`)
     - `bridge pirania pirania-catch-bridge-ifaces` (type `ifname`)
   - **Note**: Sets are table-local. Each set exists only in its own table
     and cannot be referenced from other tables.
   - Populate from UCI lists:
     - `pirania.base_config.catch_interfaces` → `pirania-catch-ifaces`
     - `pirania.base_config.catch_bridged_interfaces` → `pirania-catch-bridge-ifaces`

2. **Bridge-side marking (L2 ingress)**
   - Create `table bridge pirania` with a `prerouting` base chain.
   - For packets arriving on `@pirania-catch-bridge-ifaces`, set a mark
     (reuse the legacy mark constant to preserve semantics).
   - This replaces the old ebtables mark step.
   - Use a `dstnat`-priority base chain so marking happens early.

3. **Inet-side gating (L3 ingress)**
   - Introduce two regular chains to hold existing rules:
     - `pirania_prerouting` (nat redirect + prefilter rules)
     - `pirania_forward` (filter rules)
   - Base chains (`prerouting`, `forward`) only jump into these chains when:
     - `iifname` is in `@pirania-catch-ifaces`, OR
     - `meta mark` matches the bridge mark.
   - If both sets are empty, the base chains effectively no-op.

   **Empty set behavior**: In nftables, `iifname @empty-set` matches nothing
   (the rule never triggers). This is the desired safe-by-default behavior.
   Verification: `nft add rule ... iifname @pirania-catch-ifaces jump ...`
   with an empty set will never jump. Must be tested during implementation.

4. **Set population lifecycle**
   - Extend `update_ipsets()` to:
     - `nft flush set` and re-add `catch_*` elements.
     - Handle empty/missing UCI lists cleanly (leave set empty).
   - Ensure `clean_tables()` removes both `inet` and `bridge` tables.

5. **Mark handling**
   - Use `meta mark` for the gating bit (simple and stateless).
   - **Decision**: Do NOT clear the mark _before_ `pirania_forward` (gating would fail).
   - **Decision**: Clear the mark after Pirania processing completes.
     Rationale: The bridge mark is set globally on the skb and can affect other
     subsystems (policy routing via `ip rule fwmark`, tc/qdiscs, other nftables
     tables). Clearing after Pirania processing avoids unintended side effects.

   **Mark-clearing implementation** (nftables behavior note):
   Terminal verdicts (`accept`, `drop`) immediately exit the chain - a "final rule"
   at the end of a chain is never reached by packets that matched a terminal rule.
   Two approaches to reliably clear the mark:

   **(a) Clear before each accept** (verbose but explicit):

   ```
   chain pirania_forward {
       ether saddr @pirania-auth-macs meta mark set 0 accept
       ip daddr @pirania-allowlist-ipv4 meta mark set 0 accept
       # ... drop rules don't need clearing (packet is gone)
       drop
   }
   ```

   **(b) Use `return` instead of `accept`, clear in base chain** (recommended):

   ```
   chain forward {
       type filter hook forward priority 0; policy accept;
       iifname @pirania-catch-ifaces jump pirania_forward
       meta mark 0x9124714 jump pirania_forward
       # Packets that returned from pirania_forward reach here; clear mark
       meta mark 0x9124714 meta mark set 0
   }

   chain pirania_forward {
       ether saddr @pirania-auth-macs return        # not accept
       ip daddr @pirania-allowlist-ipv4 return      # not accept
       # ... unauthorized ...
       drop   # dropped packets never return, mark is irrelevant
   }
   ```

   **Recommendation**: Use approach (b). Single mark-clear location, cleaner logic.
   Dropped packets don't return so mark clearing is unnecessary for them.

## Complete Chain Structures

This section shows the full nftables structure for both tables.

### Bridge table (L2 marking)

```
table bridge pirania {
    # Set for bridged interface names (populated from UCI)
    set pirania-catch-bridge-ifaces {
        type ifname
    }

    # Mark packets arriving on catch interfaces
    chain prerouting {
        type filter hook prerouting priority dstnat;
        iifname @pirania-catch-bridge-ifaces meta mark set 0x9124714
    }
}
```

**Note**: Bridge family uses `type filter` (not `nat`). Priority `dstnat` (-300)
ensures marking happens early before other processing.

### Inet table (L3 gating and rules)

```
table inet pirania {
    # Set for L3 interface names (populated from UCI)
    set pirania-catch-ifaces {
        type ifname
    }

    # Existing sets (unchanged)
    set pirania-auth-macs { type ether_addr; }
    set pirania-allowlist-ipv4 { type ipv4_addr; flags interval; }
    set pirania-allowlist-ipv6 { type ipv6_addr; flags interval; }
    set pirania-tranca-allowlist-ipv4 { type ipv4_addr; flags interval; }
    set pirania-unrestricted-macs { type ether_addr; }

    # --- PREROUTING (NAT) ---
    chain prerouting {
        type nat hook prerouting priority -100;
        # Gate: only process caught interfaces or marked packets
        iifname @pirania-catch-ifaces jump pirania_prerouting
        meta mark 0x9124714 jump pirania_prerouting
        # Non-caught traffic flows through without redirect
    }

    chain pirania_prerouting {
        # Allowlist destinations pass through (no redirect)
        ip daddr @pirania-allowlist-ipv4 accept
        ip6 daddr @pirania-allowlist-ipv6 accept

        # DHCP must always work
        udp dport { 67, 68 } accept
        udp dport { 546, 547 } accept

        # Authorized MACs pass through
        ether saddr @pirania-auth-macs accept

        # Redirect HTTP to portal
        tcp dport 80 redirect to :59080

        # Redirect DNS to captive DNS
        udp dport 53 redirect to :59053

        # Drop other unauthorized traffic
        drop
    }

    # --- FORWARD (filter) ---
    chain forward {
        type filter hook forward priority 0; policy accept;
        # Gate: only process caught interfaces or marked packets
        iifname @pirania-catch-ifaces jump pirania_forward
        meta mark 0x9124714 jump pirania_forward
        # Clear bridge mark for packets that returned
        meta mark 0x9124714 meta mark set 0
        # Non-caught traffic accepted by policy
    }

    chain pirania_forward {
        # Rules here use 'return' for accept, 'drop' for block
        # (see Tranca Redes section for normal vs Tranca mode)
    }
}
```

**Note on prerouting**: Uses `accept` (not `return`) because:

- Redirected packets go to local input chain, not forward (mark clearing N/A)
- Accepted packets continue to forward chain where mark gets cleared
- Dropped packets are terminated (mark irrelevant)

**Set table-locality**: Sets are local to their table. `pirania-catch-ifaces`
exists only in `inet pirania`; `pirania-catch-bridge-ifaces` exists only in
`bridge pirania`. They cannot be referenced across tables.

## Tranca Redes Integration

Tranca Redes mode changes forward chain rule ordering. Both normal and Tranca
rules must live inside `pirania_forward` (the regular chain), gated by the
base chain's interface/mark check.

**Chain structure with Tranca support** (forward chain detail):

```
table inet pirania {
    # Base chain - only jumps on interface match or bridge mark
    chain forward {
        type filter hook forward priority 0; policy accept;
        iifname @pirania-catch-ifaces jump pirania_forward
        meta mark 0x9124714 jump pirania_forward
        # Clear bridge mark for packets that returned (accepted)
        meta mark 0x9124714 meta mark set 0
    }

    # Regular chain - uses return for accept, drop for block
    chain pirania_forward {
        # --- Rules inserted here depend on Tranca active state ---
        # Normal mode: auth-macs return, DNS return, allowlist return, drop
        # Tranca mode: allowlist return, DNS return, unrestricted return,
        #              auth-macs + tranca-allowlist return, auth-macs drop
    }
}
```

**Note**: Using `return` instead of `accept` allows the base chain to clear
the bridge mark after Pirania processing. Dropped packets never return, so
mark clearing is unnecessary for them.

**Mark-clearing rule behavior**: The rule `meta mark 0x9124714 meta mark set 0`
clears the mark for _any_ packet carrying that mark value, not exclusively
packets that returned from `pirania_forward`. This is acceptable because:
(a) the mark value `0x9124714` is unique to Pirania and should not appear
from other sources, and (b) any packet with this mark has been processed
by Pirania (or is about to be) and should have the mark cleared regardless.
The rule must be placed _after_ the jump rules to avoid clearing before gating.
If any other component uses the same mark value, choose a different dedicated
mark or use `ct mark`/flags to clear only after a confirmed jump.

**Rule placement logic** (in `set_nftables()`):

- Check `uci -q get pirania.tranca_redes.active`
- If active: insert Tranca-specific rules into `pirania_forward`
- If inactive: insert normal rules into `pirania_forward`
- The base `forward` chain remains unchanged regardless of Tranca state

**Tranca state changes** (`captive-portal update`):

- Detect state change by checking if Tranca rules are present
- If state changed: `clean_tables` + `set_nftables` (rebuild both tables)
- The gating logic (interface sets) persists through rebuild

## Legacy iptables/ebtables behavior (for reference)

- **catch_bridged_interfaces**:
  - `ebtables -t nat -A PREROUTING -i <iface> -j mark --mark-set 0x9124714`
  - Then iptables mangle PREROUTING matched `-m mark --mark 0x9124714 -j pirania`.
- **catch_interfaces**:
  - `iptables -t mangle -A PREROUTING -i <iface> -j pirania`.
- The `pirania` chain then handled allowlists, marking, and redirects.

## Practical Examples (to validate behavior)

- **Wi-Fi only (bridge AP)**:
  - `catch_bridged_interfaces = wlan0-ap`
  - `catch_interfaces` empty
  - Expect: only Wi-Fi clients are captive; wired LAN and mesh are free.
- **LAN + Wi-Fi**:
  - `catch_interfaces = br-lan`
  - `catch_bridged_interfaces = wlan0-ap`
  - Expect: everything entering LAN/bridge is captive (including wired).
- **Guest only**:
  - `catch_interfaces = br-guest`
  - `catch_bridged_interfaces = wlan1-ap`
  - Expect: only guest SSID and guest bridge are captive.
- **Multiple access points**:
  - `catch_bridged_interfaces = wlan0-ap wlan1-ap`
  - Expect: both APs captive; no mesh impact if mesh is separate.

## Pre-Implementation Checklist (router)

- Confirm ifnames:
  - `ip link`
  - `bridge link`
  - `uci show network` (map UCI networks to ifnames)
- Confirm mesh/backbone devices to exclude from catch lists.
- If you have router access, capture current ifnames:
  - `ssh 10.29.0.1 'ip link'`
  - `ssh 10.29.0.1 'bridge link'` (fallback: `ssh 10.29.0.1 'brctl show'`)
  - `ssh 10.29.0.1 'uci show network'`

## Router snapshot (10.29.0.1)

- `ip link` key ifnames: `br-lan`, `bat0`, `wlan0-ap`, `wlan0-apname`,
  `wlan0-mesh`, `eth0`, `eth1`, `anygw@br-lan`, `eth0_45`, `eth1_45`,
  `wlan0-mesh_45`, `eth0_17`, `eth1_17`, `wlan0-mesh_17`.
- `bridge link` not available (no `bridge` tool); `brctl show` reports
  `br-lan` contains: `bat0`, `eth1`, `wlan0-ap`, `wlan0-apname`.
- `uci show network` shows `br-lan` is a bridge with ports `bat0` and `eth1`,
  and mesh uses `bat0` with VLAN hardifs (`eth0_45`, `eth1_45`, `wlan0-mesh_45`).
- **Suggested initial catch list for this router**:
  - `catch_bridged_interfaces = wlan0-ap wlan0-apname`
  - `catch_interfaces` empty (unless you explicitly want wired LAN captive).
  - Avoid `bat0`/`wlan0-mesh*` to prevent mesh blocking.

**Note**: The default config uses only `wlan0-ap`. If `wlan0-apname` should also
be caught, add it to the UCI config:
```sh
uci add_list pirania.base_config.catch_bridged_interfaces='wlan0-apname'
uci commit pirania
captive-portal update
```

## Implementation Steps (high level)

1. Add new sets (inet + bridge) and bridge table/chain creation in `set_nftables()`.
2. Move existing prerouting/forward rules into new regular chains.
3. Add gating rules in base chains that jump only on interface match or mark.
4. Update `update_ipsets()` to populate the new sets from UCI.
5. Update `clean_tables()` to remove the bridge table too.

## Implementation Notes (post-implementation)

**Commit**: `eef46ef1` on branch `hotfix/pirania`

**Critical ordering requirement**: Regular chains (`pirania_prerouting`, `pirania_forward`)
**MUST** be created before base chains that reference them with `jump` rules. nftables
returns "No such file or directory" if you try to jump to a non-existent chain.

Correct order in `set_nftables()`:

```sh
# 1. Create regular chains FIRST
nft add chain inet pirania pirania_prerouting
nft add chain inet pirania pirania_forward

# 2. THEN create base chains with jump rules
nft add chain inet pirania prerouting { type nat hook prerouting priority -100; }
nft add rule inet pirania prerouting iifname @pirania-catch-ifaces jump pirania_prerouting
nft add rule inet pirania prerouting meta mark $PIRANIA_MARK jump pirania_prerouting
```

**Bridge table conditional creation**: The bridge table is only created when
`catch_bridged_interfaces` is configured. This avoids unnecessary kernel module
usage when L2 marking isn't needed.

## clean_tables() Specification

Must remove both `inet` and `bridge` family tables:

```sh
clean_tables () {
    echo "Cleaning captive-portal rules if there's any"
    # Remove bridge table first (marking)
    if nft list tables bridge | grep -q "pirania"; then
        nft delete table bridge pirania
    fi
    # Remove inet table (rules)
    if nft list tables inet | grep -q "pirania"; then
        nft delete table inet pirania
    fi
}
```

**Order**: Bridge table deleted first (marking) then inet table (rules),
though order doesn't matter functionally since they're independent.

## Validation / Checks

### Structural validation

- [x] `nft list ruleset` shows both `inet pirania` and `bridge pirania` tables
- [x] `nft list set inet pirania pirania-catch-ifaces` shows expected interfaces (empty when L3 not configured)
- [x] `nft list set bridge pirania pirania-catch-bridge-ifaces` shows expected interfaces (`wlan0-ap`)
- [x] Base chains have correct priorities (prerouting: -100, forward: 0, bridge: dstnat/-300)

### Functional validation - interface filtering

- [ ] Traffic from mesh interface (`bat0`) is NOT caught (no redirect, free access)
- [ ] Traffic from `wlan0-mesh*` is NOT caught
- [ ] Traffic from `wlan0-ap` IS caught and redirected to portal
- [ ] Traffic from `wlan0-apname` IS caught (if in catch list)
- [ ] Wired LAN traffic behavior matches configuration intent

### Functional validation - empty sets

- [ ] With both `catch_*` lists empty: no clients are caught, all traffic passes
- [x] With only `catch_bridged_interfaces` populated: only bridged AP clients caught
- [ ] With only `catch_interfaces` populated: only L3 interface traffic caught

### Functional validation - Tranca Redes

- [ ] Tranca activation rebuilds rules correctly with interface gating preserved
- [ ] Tranca deactivation restores normal rules with interface gating preserved
- [ ] Unrestricted MACs bypass Tranca restrictions (when active)
- [ ] Authorized MACs limited to category allowlist (when Tranca active)

### Functional validation - IPv6

- [ ] IPv6 client from `wlan0-ap` is correctly caught and redirected
- [ ] IPv6 allowlist destinations are accessible

### Regression validation

- [ ] Existing authorized MACs still work (voucher/read-for-access)
- [ ] Allowlist IPv4/IPv6 destinations still accessible
- [ ] DNS redirect to 59053 still works for unauthorized clients
- [ ] HTTP redirect to 59080 still works for unauthorized clients
- [ ] HTTPS (443) blocked for unauthorized clients

## Decisions (best practices)

- **Mark value**: reuse legacy `0x9124714` for continuity and easy rollback.
- **Mark type**: use `meta mark` (stateless, matches legacy ebtables mark).
- **Bridge chain priority**: use `dstnat` (`-300`) to ensure early marking.

## Branch references

- Current branch: `luandro/hotfix/pirania`.
- Legacy reference for consultation: `bb0b5a207bd8817ef89405024023959f9bdf5dc4`.

## References

- nftables wiki: Matching packet metainformation
  - https://wiki.nftables.org/wiki-nftables/index.php/Matching_packet_metainformation
- nftables wiki: Sets
  - https://wiki.nftables.org/wiki-nftables/index.php/Sets
- nftables wiki: Netfilter hooks / priorities
  - https://wiki.nftables.org/wiki-nftables/index.php/Netfilter_hooks
- nftables wiki: Configuring chains
  - https://wiki.nftables.org/wiki-nftables/index.php/Configuring_chains
- OpenWrt wiki: firewall configuration (nftables.d drop-in includes)
  - https://openwrt.org/docs/guide-user/firewall/firewall_configuration
