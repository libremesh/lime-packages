#!/bin/sh

SPRUNGE_URL="http://sprunge.us"

TEMP_FILE="$(mktemp)"
COMMAND="$0 $@"

usage()
{
	echo -e "Suggested ways of using $0 are mainly 3\nyourCommand | $0\n$0 [ -c command ]\n$0 [ -f file ]" 1>&2 ; exit 0
}

case "${1}" in
	"-h") usage ;;
	"--help") usage ;;
	"-c") echo "${COMMAND}" > "${TEMP_FILE}" ; ${2} | tee -a "${TEMP_FILE}" ;;
	"-f") echo "${COMMAND}" > "${TEMP_FILE}" ; cat "${2}" | tee -a "${TEMP_FILE}" ;;
	*) tee <&0 "${TEMP_FILE}" ;;
esac

cat "${TEMP_FILE}" | curl -F 'sprunge=<-' "${SPRUNGE_URL}" 1>&2

rm -f "${TEMP_FILE}"
