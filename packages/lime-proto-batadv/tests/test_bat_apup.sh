#!/bin/bash
# configure at least three routers with apup and limed, only leave one of them
# on and turn the rest off.
# run this script on a computer connected to the node to start limed and u-bus
# listen. 
# turn on the other nodes and wait for them to connect

NODE_IP="thisnode.info"        
SSH_USER="root"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

ssh $SSH_OPTS "$SSH_USER@$NODE_IP" <<EOF

echo "[1/4] Bringing Wi-Fi down..."
wifi down


echo "[2/4] Starting limed and ubus listen ..."
echo "------------------------------------------"
(
  /usr/bin/limed 2>&1 | while IFS= read -r line; do
    echo "[\$(date +'%Y-%m-%d %H:%M:%S')] [limed] \$line"
  done &
  LIMED_PID=\$!

  ubus listen 2>&1 | while IFS= read -r line; do
    echo "[\$(date +'%Y-%m-%d %H:%M:%S')] [ubus] \$line"
  done &
  UBUS_PID=\$!

  sleep 2
  echo "------------------------------------------"
  sleep 2
  echo "------------------------------------------"
  sleep 2

  echo "[3/4] Bringing Wi-Fi up..."
  wifi up

  echo "[4/4] Now you should be able to see new connections. Press Ctrl+C to stop."
  wait \$LIMED_PID \$UBUS_PID
)
EOF


###### sample output
# [1/4] Bringing Wi-Fi down...
# [2/4] Starting limed and ubus listen ...
# ------------------------------------------
# [2025-07-31 21:35:06] [limed]  'hostapd' namespace exists...
# [2025-07-31 21:35:07] [ubus] { "ubus.object.remove": {"id":1399214265,"path":"hostapd.wlan1-apup"} }
# ------------------------------------------
# ------------------------------------------
# [3/4] Bringing Wi-Fi up...
# [4/4] Now you should be able to see new connections. Press Ctrl+C to stop.
# [2025-07-31 21:35:16] [ubus] { "ubus.object.add": {"id":-1307156726,"path":"hostapd.wlan1-apup"} }


# [2025-07-31 21:36:02] [limed] Subscribing: hostapd.wlan1-apup
# [2025-07-31 21:36:03] [limed] peerSubscriber type: apup-newpeer data.ifname: wlan1-peer1 
# [2025-07-31 21:36:03] [ubus] { "ubus.object.add": {"id":565721540,"path":"network.interface.lm_net_lm_net_wlan1_peer1_static"} }
# [2025-07-31 21:36:03] [limed] lime.network.runProtocols(wlan1-peer1, ...)
# [2025-07-31 21:36:03] [limed] lime.proto.batadv.runOnDevice(wlan1-peer1, ...)
# [2025-07-31 21:36:03] [limed] lime.network.createVlan(wlan1-peer1, ...)
# [2025-07-31 21:36:03] [limed]           vid      =      29
# [2025-07-31 21:36:03] [limed]           type     =      8021ad
# [2025-07-31 21:36:03] [limed]           name     =      wlan1-peer1_29
# [2025-07-31 21:36:03] [ubus] { "ubus.object.add": {"id":-1500836794,"path":"network.interface.lm_net_wlan1-peer1_batadv"} }
# [2025-07-31 21:36:03] [limed]           ifname   =      wlan1-peer1
# [2025-07-31 21:36:04] [ubus] { "network.interface": {"action":"ifup","interface":"lm_net_lm_net_wlan1_peer1_29_static"} }
# [2025-07-31 21:36:04] [ubus] { "ubus.object.add": {"id":-1232818779,"path":"network.interface.lm_net_lm_net_wlan1_peer1_29_static"} }
# [2025-07-31 21:36:04] [ubus] { "network.interface": {"action":"ifup","interface":"lm_net_wlan1-peer1_batadv"} }
# [2025-07-31 21:36:04] [limed] batadv createdwlan1-peer1_29 with address:02:58:11:22:55:bc and static lm_net_lm_net_wlan1_peer1_29_static
# [2025-07-31 21:36:04] [limed] lime.proto.babeld.runOnDevice(wlan1-peer1, ...)
# [2025-07-31 21:36:04] [limed] lime.network.createVlan(wlan1-peer1, ...)
# [2025-07-31 21:36:04] [limed]           vid      =      17
# [2025-07-31 21:36:04] [limed]           type     =      8021ad
# [2025-07-31 21:36:04] [limed]           name     =      wlan1-peer1_17
# [2025-07-31 21:36:04] [limed]           ifname   =      wlan1-peer1
# [2025-07-31 21:36:04] [ubus] { "network.interface": {"action":"ifup","interface":"lm_net_lm_net_wlan1_peer1_17_static"} }
# [2025-07-31 21:36:04] [ubus] { "ubus.object.add": {"id":-1137476629,"path":"network.interface.lm_net_lm_net_wlan1_peer1_17_static"} }
# [2025-07-31 21:36:05] [limed] ip: RTNETLINK answers: File exists
# [2025-07-31 21:36:05] [ubus] { "ubus.object.add": {"id":-366401286,"path":"network.interface.lm_net_lm_net_wlan1_peer2_static"} }
# [2025-07-31 21:36:06] [ubus] { "ubus.object.add": {"id":-82673599,"path":"network.interface.lm_net_wlan1-peer2_batadv"} }
# [2025-07-31 21:36:06] [ubus] { "network.interface": {"action":"ifup","interface":"lm_net_lm_net_wlan1_peer2_29_static"} }
# [2025-07-31 21:36:06] [ubus] { "ubus.object.add": {"id":-1777215837,"path":"network.interface.lm_net_lm_net_wlan1_peer2_29_static"} }
# [2025-07-31 21:36:07] [ubus] { "network.interface": {"action":"ifup","interface":"lm_net_wlan1-peer2_batadv"} }
# [2025-07-31 21:36:07] [ubus] { "network.interface": {"action":"ifup","interface":"lm_net_lm_net_wlan1_peer2_17_static"} }
# [2025-07-31 21:36:07] [ubus] { "ubus.object.add": {"id":-1538210722,"path":"network.interface.lm_net_lm_net_wlan1_peer2_17_static"} }
# [2025-07-31 21:36:08] [limed] peerSubscriber type: apup-newpeer data.ifname: wlan1-peer2 
# [2025-07-31 21:36:08] [limed] ip: RTNETLINK answers: File exists
# [2025-07-31 21:36:08] [limed] lime.network.runProtocols(wlan1-peer2, ...)
# [2025-07-31 21:36:08] [limed] lime.proto.batadv.runOnDevice(wlan1-peer2, ...)
# [2025-07-31 21:36:08] [limed] lime.network.createVlan(wlan1-peer2, ...)
# [2025-07-31 21:36:08] [limed]           vid      =      29
# [2025-07-31 21:36:08] [limed]           type     =      8021ad
# [2025-07-31 21:36:08] [limed]           name     =      wlan1-peer2_29
# [2025-07-31 21:36:08] [limed]           ifname   =      wlan1-peer2
# [2025-07-31 21:36:08] [limed] ip: RTNETLINK answers: File exists
# [2025-07-31 21:36:08] [limed] ip: RTNETLINK answers: File exists
# [2025-07-31 21:36:09] [limed] batadv createdwlan1-peer2_29 with address:02:f4:ce:22:55:bc and static lm_net_lm_net_wlan1_peer2_29_static
# [2025-07-31 21:36:09] [limed] lime.proto.babeld.runOnDevice(wlan1-peer2, ...)
# [2025-07-31 21:36:09] [limed] lime.network.createVlan(wlan1-peer2, ...)
# [2025-07-31 21:36:09] [limed]           vid      =      17
# [2025-07-31 21:36:09] [limed]           type     =      8021ad
# [2025-07-31 21:36:09] [limed]           name     =      wlan1-peer2_17
# [2025-07-31 21:36:09] [limed]           ifname   =      wlan1-peer2
# [2025-07-31 21:36:09] [limed] ip: RTNETLINK answers: File exists
# [2025-07-31 21:36:09] [limed] ip: RTNETLINK answers: File exists
