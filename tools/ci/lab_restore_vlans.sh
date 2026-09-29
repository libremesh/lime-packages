#!/usr/bin/env bash
# Restore DUT switch ports to their isolated VLANs.
#
# Mesh runs move every participating DUT port to the shared mesh VLAN (200).
# libremesh-tests restores them from a session-scoped fixture teardown, which
# does not run when the job is cancelled or pytest is killed. A leaked VLAN 200
# then breaks every later single-node job on that DUT: U-Boot DHCPs on the mesh
# subnet instead of the DUT's isolated one, and the host cannot reach the DUT
# over its own VLAN, so the run dies in TFTP or in SSH with no obvious cause.
#
# Running this both after mesh jobs (with `if: always()`) and before single-node
# jobs makes each job independent of whatever state the previous one left.
#
# Usage: lab_restore_vlans.sh <place> [<place>...]
# Places accept the labgrid prefix or the bare DUT name.
set -uo pipefail

PLACE_PREFIX="${PLACE_PREFIX:-labgrid-fcefyn-}"
PROXY="${LG_PROXY:-labgrid-fcefyn}"
PROXY="${PROXY#ssh://}"

if [[ $# -eq 0 ]]; then
	echo "usage: $0 <place> [<place>...]" >&2
	exit 2
fi

duts=()
for place in "$@"; do
	[[ -n "$place" ]] || continue
	duts+=("${place#"$PLACE_PREFIX"}")
done

if [[ ${#duts[@]} -eq 0 ]]; then
	echo "No DUTs to restore"
	exit 0
fi

# Mirrors conftest_vlan._switch_timeout: the TP-Link JetStream CLI needs about
# a second per command and switch-vlan issues several per DUT.
timeout_sec=$((30 + 10 * ${#duts[@]}))

echo "Restoring DUT ports to their isolated VLANs: ${duts[*]}"
if timeout "$timeout_sec" ssh "$PROXY" "switch-vlan ${duts[*]} --restore"; then
	exit 0
fi

# Best effort by design: as cleanup it must not mask the real test result, and
# as a pre-step the test itself reports the connectivity failure far better
# than an opaque non-zero exit here would.
echo "::warning::VLAN restore failed for: ${duts[*]}. Jobs using these DUTs may not reach them; run 'switch-vlan --restore-all' on the lab host."
