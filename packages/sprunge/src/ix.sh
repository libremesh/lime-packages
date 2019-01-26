#!/bin/sh

IX_HOST="ix.io"

TEMP_FILE="$(mktemp)"
TEMP_FILE_ENCODED="$(mktemp)"
COMMAND="$0 $@"

usage()
{
	echo "\
ix: Command line pastebin

Suggested ways of using $0 are mainly 4:
yourCommand arg1 arg2 | $0
$0 -c \"yourCommand arg1 arg2\"
$0 -f file
$0; then EOF using Ctrl+D" 1>&2

	exit 0
}

case "${1}" in
	"-h") usage ;;
	"--help") usage ;;
	"-c")
		echo "${COMMAND}" > "${TEMP_FILE}"
		eval "${2}" | tee -a "${TEMP_FILE}"
		;;
	"-f")
		echo "${COMMAND}" > "${TEMP_FILE}"
		cat "${2}" | tee -a "${TEMP_FILE}"
		;;
	*) tee <&0 "${TEMP_FILE}" ;;
esac

cat "${TEMP_FILE}" | hexdump -v -e '/1 "%02x"' \
	| sed 's/\(..\)/%\1/g' > "${TEMP_FILE_ENCODED}"

echo -n "POST / HTTP/1.0
Host: ${IX_HOST}
Content-Length: $(( $(cat ${TEMP_FILE_ENCODED} | wc -m) + 4 ))
Content-Type: application/x-www-form-urlencoded

f:1=$(cat ${TEMP_FILE_ENCODED})" \
	| nc "${IX_HOST}" 80 \
	| grep "${IX_HOST}" 1>&2

rm -f "${TEMP_FILE}" "${TEMP_FILE_ENCODED}"
