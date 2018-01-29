#!/bin/sh

trusted_ids=$(uci -q get lime-defaults.trusted_nodes.node_id)

[[ -z "$trusted_ids" ]]  && {
    echo "please add section trusted_nodes in lime-defaults"
    exit 1
}

echo "checking"
# get all recevied configs
for config_path in /var/run/bmx7/sms/rcvdSms/*lime-defaults; do
    # check if installed config is older then received config
    if [[ "$(sha256sum /etc/config/lime-defaults | cut -c -32)" != "$(sha256sum "$config_path" | cut -c -32)" ]]; then
        echo "found new config"
        # get filename without path
        config_file="$(basename $config_path)"
        # parse node id
        node_id="${config_file%%:*}"
        # check if node is trusted
        for trusted_id in $trusted_ids; do
            if [[ "$node_id" == "$trusted_id" ]]; then
                echo "$node_id: trusted config found"
                # replace outdated config
                cp $config_path /etc/config/lime-defaults
                lime-config
                lime-apply
                exit
            else
                echo "$node_id: ignoring untrusted config"
            fi
        done
    fi
done
