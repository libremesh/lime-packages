#!/bin/sh

. /usr/share/libubox/jshn.sh

trusted_ids=$(uci -q get lime-defaults.trusted_nodes.node_id)
[[ -z "$trusted_ids" ]]  && {
	trusted_ids=$(uci -q get lime.trusted_nodes.node_id)
	[[ -z "$trusted_ids" ]] && {
		uci -q set lime.trusted_nodes="trusted_nodes"
		uci -q set lime.trusted_nodes.node_id=""
		echo "please add section trusted_nodes in /etc/config/lime"
		exit 1
	}
}

bmx7_shortid="$(uci -q get lime.system.bmx7_shortid)"
[[ -z "$bmx7_shortid" ]] && {
	json_load "$(cat /var/run/bmx7/json/status)"
	json_select status
	json_get_var bmx7_shortid shortId
	uci -q set lime.system.bmx7_shortid="$bmx7_shortid"
}

for trusted_id in $trusted_ids; do
	[[ -z "$trusted_id" ]] && return
	for config_file in ls /var/run/bmx7/sms/rcvdSms/${trusted_id}*; do
		if [[ "$(basename $config_file)" == "${trusted_id}:lime-defaults" ]]; then
			cp $config_file /etc/config/lime-defaults
			changes=1
		elif [[ "$(basename $config_file)" == "${trusted_id}:hn_${bmx7_shortid}" ]]; then
			uci -q set lime.system.hostname="$(cat $config_file)"
			changes=1
		fi
	done
done

[[ -n "$changes" ]] && {
	lime-config
	lime-apply
}
