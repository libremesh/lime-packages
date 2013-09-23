#!/bin/sh

DEVS="wbm1 wbm2"

incoming_wifi_activity()
{
	WIFIDEV="$1"
	local funcname="incoming_wifi_activity"
	local framecount_old framecount_new check_dev uptime_old uptime_new uptime_diff
	local file_framecount="/tmp/WIFI_INCOMING_FRAME_COUNTER_$WIFIDEV"
	local file_activity_seen="$file_framecount.active"
	local file_uptime="$file_framecount.uptime"
	local monitoring_vif="mon.$WIFIDEV"
	local logprio="alert"
	local trash

	[ -z "$WIFIDEV" ] && return 0

	if fgrep -q "$monitoring_vif:" /proc/net/dev; then
		check_dev="$monitoring_vif"
	else
		check_dev="$WIFIDEV"
	fi

	eval "$( sed -n "s/.*${check_dev}: *[0-9]* *\([0-9]*\).*/framecount_new=\1/p" /proc/net/dev )"

	read uptime trash </proc/uptime
	uptime_new="${uptime%.*}"	# was: uptime_new="$( _system uptime )"
	read uptime_old 2>/dev/null <"$file_uptime"
	echo "$uptime_new" >"$file_uptime"
	uptime_diff="$(( $uptime_new - ${uptime_old:-0} ))"

	[ $uptime_diff -gt 65 ] && \
		logger -s "[ERR] timediff > 60 sec = $uptime_diff"

	if [ -e "$file_framecount" ]; then
		read framecount_old <"$file_framecount"
	else
		framecount_old="-1"			# ensures, that first start is without errors
	fi

	echo "$framecount_new" >"$file_framecount"

	if [ "$framecount_old" = "$framecount_new" ]; then
		[ "$framecount_new" = "0" ] && logprio="info"
		logger -s "[ERR] framecounter for $check_dev old/new: $framecount_old = $framecount_new timediff: $uptime_diff sec"
		echo "0" >"$file_framecount"

		if [ $uptime_diff -ge 60 ]; then
			if [ -e "$file_activity_seen" ]; then
				rm "$file_activity_seen"
				return 1
			else
				return 0
			fi
		else
			return 0
		fi
	else
		[ -e "$file_activity_seen" ] || {
			[ "$framecount_old" = "-1" ] || {
				logger -s "[OK] first activity seen on dev $check_dev ($framecount_old packets) - marking"
				touch "$file_activity_seen"
			}
		}

		logger -s "[OK] framecounter for dev $check_dev: old + diff = new : $framecount_old + $(( $framecount_new - $framecount_old )) (during $uptime_diff sec)"
#		logger -s "[OK] framecounter for dev $check_dev: old + diff = new : $( _sanitizer do "$framecount_old + $(( $framecount_new - $framecount_old )) = $framecount_new" number_humanreadable ) (during $uptime_diff sec)"
		return 0
	fi
}


for d in $DEVS; do 
	incoming_wifi_activity $d || { 
		echo "Wifi device $d is down, activating..."
		wifi up
		echo "done..."
	}
done

