from net import IpAddress

when defined(windows) or defined(nimdoc):
    from winlean import SockAddr, Sockaddr_in, Sockaddr_in6, AF_INET, AF_INET6, SockLen
elif defined(linux) or defined(maxosx):
    from posix import SockAddr, Sockaddr_in, Sockaddr_in6, AF_INET, AF_INET6, SockLen

from nativesockets import Port
from net import fromSockAddr


proc fromSockAddrPtr*(sa: ptr SockAddr, address: var IpAddress, flowInfo: var uint32,
                      scopeId: var uint32) =
    var port: Port
    if sa.sa_family.uint32 == AF_INET.uint32:
        let sa4 = cast[ptr Sockaddr_in](sa)[]
        let size = sizeof(Sockaddr_in).SockLen
        fromSockAddr(sa4, size, address, port)
    elif sa.sa_family.uint32 == AF_INET6.uint32:
        let sa6 = cast[ptr Sockaddr_in6](sa)[]
        let size = sizeof(Sockaddr_in6).SockLen
        fromSockAddr(sa6, size, address, port)
        flowInfo = sa6.sin6_flowinfo.uint32
        scopeId = sa6.sin6_scope_id.uint32
    else:
        raise newException(Exception, "unknown sa_family")
