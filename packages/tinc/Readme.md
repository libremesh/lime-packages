# tinc

## Tinc, LibreMesh and librenet6
tinc is used to make IPV6 connections with librenet6, our global VPN to support and interconnect community networks. You can read more [about librenet6 here](https://github.com/libremesh/librenet6).

## What is tinc?
**tinc** is a Virtual Private Network (VPN) daemon that uses tunnelling and encryption to create a secure private network between hosts on the Internet. tinc is Free Software and licensed under the GNU General Public License version 2 or later. Because the VPN appears to the IP level network code as a normal network device, there is no need to adapt any existing software. This allows VPN sites to share information with each other over the Internet without exposing any information to others. In addition, tinc has the following features:

### Encryption, authentication and compression
All traffic is optionally compressed using zlib or LZO, and LibreSSL or OpenSSL is used to encrypt the traffic and protect it from alteration with message authentication codes and sequence numbers.

### Automatic full mesh routing
Regardless of how you set up the tinc daemons to connect to each other, VPN traffic is always (if possible) sent directly to the destination, without going through intermediate hops.

### NAT traversal
As long as one node in the VPN allows incoming connections on a public IP address (even if it is a dynamic IP address), tinc will be able to do NAT traversal, allowing direct communication between peers.

### Easily expand your VPN
When you want to add nodes to your VPN, all you have to do is add an extra configuration file, there is no need to start new daemons or create and configure new devices or network interfaces.

### Ability to bridge ethernet segments
You can link multiple ethernet segments together to work like a single segment, allowing you to run applications and games that normally only work on a LAN over the Internet.
Runs on many operating systems and supports IPv6
Currently Linux, FreeBSD, OpenBSD, NetBSD, OS X, Solaris, Windows 2000, XP, Vista and Windows 7 and 8 platforms are supported. See our section about supported platforms for more information about the state of the ports. tinc has also full support for IPv6, providing both the possibility of tunneling IPv6 traffic over its tunnels and of creating tunnels over existing IPv6 networks.
