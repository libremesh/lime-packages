#!/bin/sh

action="$1"
client_mac="${2:-unknown_mac}"
voucher="$3"

free_keyword=JustForToday
free_secs=108000 #seconds = 30 hours
free_limit_down=512 #kbps
free_limit_up=128 #kbps
vale_blacklist=/etc/nodogsplash/vale/blacklist_$(date +%Y%m).log
vale_db=/etc/nodogsplash/vale/db.csv
vale_secs=2592000 #seconds = 30 days

now_epoch="$(date +%s)"
free_first_use_epoch="$(cat "$vale_blacklist" | grep "$client_mac" | cut -d ' ' -f 1 | head -n 1)"
free_expire_epoch="$(($free_first_use_epoch + $free_secs))"
free_remaining_secs="$(($free_expire_epoch - $now_epoch))"
vale_used_epoch="$(egrep -i "$client_mac" "$vale_db" | cut -d , -f 3 | sort -nr | head -n 1)"
vale_expire_epoch="$(($vale_used_epoch + $vale_secs))"
vale_remaining_secs="$(($vale_expire_epoch - $now_epoch))"

tolower() {
  echo "$@" | tr ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz
}

vale() { client_mac="$1" ; voucher="$2"
  [ -n "$voucher" ] && vale_row="$(cut -d , -f 2- "$vale_db" | egrep -i "^${voucher},")"
  if [ -n "$vale_row" ] ; then
    if echo "$vale_row" | grep -iq "^${voucher},,$" ; then
      vale_used_epoch=$now_epoch
      vale_used_macs=$client_mac
    elif echo "$vale_row" | grep -iq "^${voucher}," ; then
      vale_used_epoch="$(grep -i "$voucher" "$vale_db" | cut -d , -f 3)"
      vale_used_macs="$(grep -i "$voucher" "$vale_db" | cut -d , -f 4)"
      if ! (echo $vale_used_macs | grep -q $client_mac) ; then
        vale_used_macs="$vale_used_macs+$client_mac"
      fi
    fi
    vale_expire_epoch="$(($vale_used_epoch + $vale_secs))"
    sed -i "s/$voucher.*$/$voucher,$vale_used_epoch,$vale_used_macs/i" "$vale_db"
    vale_remaining_secs="$(($vale_expire_epoch - $now_epoch))"
  fi

  [ "$vale_remaining_secs" -lt 0 ] && vale_remaining_secs=0
  echo "$vale_remaining_secs"
}

client_hostname="$(grep " $client_mac " /tmp/dhcp.leases | cut -d ' ' -f 4 | grep -v '\*')"
[ -n "$client_hostname" ] && log_info="($client_hostname)"
echo "$now_epoch" "$@" "$log_info" | grep -v auth_status >> /etc/nodogsplash/vale/debug.log

#sanitize input, forcing lowercase and allowing only alphanum
voucher="$(tolower "$voucher" | tr -c -d abcdefghijklmnopqrstuvwxyz1234567890)"

if [ "$action" == "auth_voucher" ] ; then

  if [ "$vale_remaining_secs" -gt 0 ] ; then
    echo "$vale_remaining_secs" 102400 102400
  else
    if [ "$free_remaining_secs" -gt 0 ] ; then
      echo "$free_remaining_secs" "$free_limit_down" "$free_limit_up"
    else
      if [ "$(tolower "$voucher")" == "$(tolower "$free_keyword")" ] ; then
        if ( grep -q "$client_mac" "$vale_blacklist" ) ; then
          echo 0 0 0 ; exit 0
        else
          echo "$now_epoch" "$client_mac" >> $vale_blacklist
          echo "$free_secs" "$free_limit_down" "$free_limit_up"
        fi
      else
        vale_time=$(vale "$client_mac" "$voucher")
        echo ${vale_time:-0} 102400 102400
      fi
    fi
  fi

elif [ "$action" == "auth_status" ] ; then
  # do nothing, captive portal should be seen once a day minimum
  true
fi
