#!/bin/sh
# from https://github.com/freifunk-gluon/gluon/blob/main/scripts/lint-sh.sh

set -e

is_scriptfile() {
	echo "$1" | grep -q '\.sh$' || head -n1 "$1" | grep -qE '^#!(.*\<bash|/bin/sh)$'
}

is_initscript() {
	head -n1 "$1" | grep -qxF '#!/bin/sh /etc/rc.common'
}

local="$1"
if [ "$local" != "" ]; then
    if [ -d "./${local}" ]; then
        find "./${local}" -type f | while read -r file; do
            is_scriptfile "$file" || continue

            echo "Checking $file"
            shellcheck -f gcc "$file"
        done
    elif [ -f "./${local}" ]; then
        echo "Checking $local"
        shellcheck -f gcc "$local"
    fi
    return
fi

find tools -type f | while read -r file; do
	is_scriptfile "$file" || continue

	echo "Checking $file"
	shellcheck -f gcc "$file"
done

find packages -type f | while read -r file; do
	if is_scriptfile "$file"; then
		echo "Checking $file"
		shellcheck -f gcc -x -s sh -e SC2039,SC3043,SC3037,SC3057 "$file"
	elif is_initscript "$file"; then
		echo "Checking $file (initscript)"
		shellcheck -f gcc -x -s sh -e SC2034,SC2039,SC3043,SC3037,SC3057 "$file"
	fi
done

shellcheck -f gcc -x run_tests
