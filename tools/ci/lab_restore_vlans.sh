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
# Run this after mesh jobs with `if: always()` so cancellation still restores,
# and once before the single-node jobs so they do not inherit a leaked VLAN.
#
# Usage:
#   lab_restore_vlans.sh --all             restore every DUT in the lab
#   lab_restore_vlans.sh <place>...        restore the given places
#
# Places accept the labgrid prefix or the bare DUT name.
#
# Deliberately no external timeout: switch-vlan serialises on /tmp/switch.lock,
# the same lock every PoE operation takes, and brings its own lock, connect and
# config-mode timeouts. Killing it from outside can cut an SSH session while the
# TP-Link is in config mode, which that firmware is slow to release and which
# can leave the port half-configured.
#
# When a cancelled run's cleanup steps all power-off their DUTs at once,
# the lock can be held for 6x ~20s = ~120s. The default 60s is not enough,
# so we raise it to 180s.
set -uo pipefail

PLACE_PREFIX="${PLACE_PREFIX:-labgrid-fcefyn-}"
PROXY="${LG_PROXY:-labgrid-fcefyn}"
PROXY="${PROXY#ssh://}"

# Cover the worst case: every DUT's cleanup step queued on the switch lock.
LOCK_TIMEOUT="${SWITCH_LOCK_TIMEOUT:-180}"

if [[ $# -eq 0 ]]; then
	echo "usage: $0 --all | <place> [<place>...]" >&2
	exit 2
fi

if [[ "$1" == "--all" ]]; then
	echo "Restoring every DUT port to its isolated VLAN (lock timeout ${LOCK_TIMEOUT}s)"
	# shellcheck disable=SC2029
	if ssh "$PROXY" "SWITCH_LOCK_TIMEOUT=$LOCK_TIMEOUT switch-vlan --restore-all"; then
		exit 0
	fi
	echo "::warning::VLAN restore-all failed. DUTs may be stranded on the mesh VLAN; run 'switch-vlan --restore-all' on the lab host."
	exit 0
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

echo "Restoring DUT ports to their isolated VLANs: ${duts[*]} (lock timeout ${LOCK_TIMEOUT}s)"
# SC2029: expanding the DUT names locally is the intent -- they come from the
# workflow matrix, and the remote side must receive them already resolved.
# shellcheck disable=SC2029
if ssh "$PROXY" "SWITCH_LOCK_TIMEOUT=$LOCK_TIMEOUT switch-vlan ${duts[*]} --restore"; then
	exit 0
fi

# Best effort by design: as cleanup it must not mask the real test result, and
# as a pre-step the test itself reports the connectivity failure far better
# than an opaque non-zero exit here would.
echo "::warning::VLAN restore failed for: ${duts[*]}. Jobs using these DUTs may not reach them; run 'switch-vlan --restore-all' on the lab host."
