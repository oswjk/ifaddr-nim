from net import IpAddressFamily
from strutils import join, toHex
from sequtils import mapIt

import ifaddr

proc `$`(ip: IP): string =
    case ip.ip.family
    of IpAddressFamily.IPv6:
        result = join(mapIt(ip.ip.address_v6, it.toHex()), ":")
    of IpAddressFamily.IPv4:
        result = join(ip.ip.address_v4, ".")
    result &= "/" & $ip.networkPrefix

for adapter in getAdapters():
    echo("IPs of network adapter ", adapter.niceName)
    for ip in adapter.ips:
        echo("  ", ip)
