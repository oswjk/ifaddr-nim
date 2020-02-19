import bitops
from nativesockets import getAddrString, ntohl, Port
import os
from posix import SockAddr, AF_INET, AF_INET6, Sockaddr_in, Sockaddr_in6, SockLen
import tables

import private/utils

type
    ifaddrs {.importc: "struct ifaddrs", header: "<ifaddrs.h>".} = object
        ifa_next: ptr ifaddrs
        ifa_name: cstring
        ifa_flags: cuint
        ifa_addr: ptr SockAddr
        ifa_netmask: ptr SockAddr
        # Skip fields we don't care about

proc getifaddrs(ifap: ptr ptr ifaddrs): cint {.importc, header: "<ifaddrs.h>".}

proc freeifaddrs(ifa: ptr ifaddrs) {.importc, header: "<ifaddrs.h>".}

proc getPrefixLen(sa: ptr SockAddr): int =
    if sa.sa_family.uint32 == AF_INET.uint32:
        let sa4 = cast[ptr Sockaddr_in](sa)
        result = countLeadingZeroBits(bitnot(ntohl(sa4.sin_addr.s_addr)))
    elif sa.sa_family.uint32 == AF_INET6.uint32:
        # TODO: not sure if this is exactly the right thing to do ...
        let sa6 = cast[ptr Sockaddr_in6](sa)
        for i in 0..15:
            inc(result, countSetBits(sa6.sin6_addr.s6_addr[i].uint8))
    else:
        result = 0

proc getAdapters*(): seq[Adapter] =
    var addrs: ptr ifaddrs

    if getifaddrs(addr addrs) != 0:
        raiseOSError(osLastError(), "getifaddrs")

    defer: freeifaddrs(addrs)

    var ips = initOrderedTable[string, Adapter]()

    var curr = addrs
    while curr != nil:
        let name = $curr.ifa_name
        if curr.ifa_addr != nil:
            var
                ip: IpAddress
                flowInfo: uint32
                scopeId: uint32
            try:
                fromSockAddrPtr(curr.ifa_addr, ip, flowInfo, scopeId)
            except:
                curr = curr.ifa_next
                continue
            if name notin ips:
                ips[name] = Adapter(name: name, niceName: name, ips: @[])
            let prefix = getPrefixLen(curr.ifa_netmask)
            case ip.family
            of IpAddressFamily.IPv6:
                ips[name].ips.add(IP(family: IpAddressFamily.IPv6,
                    flowInfo: flowInfo,
                    scopeId: scopeId,
                    ip: ip,
                    networkPrefix: prefix,
                    niceName: name))
            of IpAddressFamily.IPv4:
                ips[name].ips.add(IP(family: IpAddressFamily.IPv4,
                    ip: ip,
                    networkPrefix: prefix,
                    niceName: name))
        curr = curr.ifa_next

    result = @[]
    for v in ips.values:
        result.add(v)
