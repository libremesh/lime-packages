#!/bin/sh

bmx7_add_sms_entry() {
	bmx7 -c syncSms="${1}"
	#uci set bmx7.${1}="syncSms"
	#uci set bmx7.${1}.syncSms="${1}"
}

bmx7_del_sms_entry() {
	uci delete bmx7.${1}
}

bmx7_add_sms_file() {
#mkdir -p /var/run/bmx7/sms/sendSms/
	filename = "basename($1)"
	bmx7_add_sms_entry "${filename}"
	ln -s "$1" "/var/run/bmx7/sms/sendSms/${filename}"
}

bmx7_del_sms_file() {
	filename = "basename($1)"
	#bmx7_del_sms_entry "${filename}"
	rm "/var/run/bmx7/sms/sendSms/${filename}"
}

bmx7_apply_changes() {
	uci commit bmx7
	/etc/init.d/bmx7 reload
}

sync_defaults() {
	case $1 in
		true|1)
			echo "sync lime-defauls with the cloud"
			bmx7_add_sms_file "/etc/config/lime-defaults"
		;;
		false|0)
			echo "stop sync of lime-defauls"
			bmx7_del_sms_file "/etc/config/lime-defaults"
		;;
		*)
			echo "unknown option for -l|--lime-defaults"
		;;
	esac

	#bmx7_apply_changes
}

set_node_hostname() {
	echo "set node shortId ${1} to ${2}"
	echo "$2" > "/var/run/bmx7/sms/sendSms/hn_${1}"
	bmx7_add_sms_entry "hn_${1}"
}

while [ "$#" ]; do
	case $1 in
		-d=*|--lime-defaults=*)
			sync_defaults "{i#*=}"
			shift
		;;
		-h|--hostname)
			set_node_hostname "$2" "$3"
			shift; shift; shift
		;;
		-l|--list-nodes)
			bmx7 -c originators | tail -n +3 | awk '{ print $1" "$2 }'
			shift
		;;
		*)
			break
		;;
	esac
done
