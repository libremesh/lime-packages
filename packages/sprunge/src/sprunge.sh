#!/bin/sh

SPRUNGE_URL="http://sprunge.us"

TEMP_FILE="$(mktemp)"
COMMAND="$0 $@"

usage()
{
	echo -e "sprunge: command line paste bin\n\nSuggested ways of using $0 are mainly 4\nyourCommand arg1 arg2 | $0\n$0 [ -c \"yourCommand arg1 arg2\" ]\n$0 [ -f file ]\n$0; then EOF using Ctrl+D" 1>&2 ; exit 0
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
