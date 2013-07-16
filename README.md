About the code structure
-----------------------------------------------------------------------------------------------------------
The Makefile found in the same directory of this README is for OpenWRT. It can be imported as a package.
Inside the src/ directory the C code of dhcpdiscover can be found. 
If you want to compile it for your computer execute: cd src && make

-----------------------------------------------------------------------------------------------------------

Program: dhcpdiscover $Revision: 2$
 *
 * License: GPL
 * Copyright (c) 2001-2004 Ethan Galstad (nagios@nagios.org)
 * Copyright (c) 2006-2013 OpenWRT.org 
 * ====================================================== 
 * Mike Gore 25 Aug 2005 
 *    Modified for standalone operation 
 * ====================================================== 
 * Pau Escrich Jun 2013 
 *    Added -b option and ported to OpenWRT 
 * ====================================================== 
 *
 ** License Information:
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 * $Id: dhcpdiscover.c,v 2$
 *

This program checks the existence and more details of a DHCP server

```
Usage: dhcpdiscover [-s serverip] [-r requestedip] [-m clientmac ] [-b bannedip] [-t timeout] [-i interface]
                  [-v] -s, --serverip=IPADDRESS
   IP address of DHCP server that we must hear from
 -r, --requestedip=IPADDRESS
   IP address that should be offered by at least one DHCP server
 -m, --mac=MACADDRESS
   Client MAC address to use for sending packets
 -b, --bannedip=IPADDRESS
   Server IP address to ignore
 -t, --timeout=INTEGER
   Seconds to wait for DHCPOFFER before timeout occurs
 -i, --interface=STRING
   Interface to to use for listening (i.e. eth0)
 -v, --verbose
   Print extra information (command-line use only)
 -h, --help
   Print detailed help screen
 -V, --version
   Print version information

Example: sudo ./dhcpdiscover -i eth0 -b 192.168.1.1
```
