from net import IpAddress, IpAddressFamily

type
    Adapter* = object
        ## Represents a network interface device controller, such as a network card. An adapter can
        ## have multiple IP addresses.
        ips*: seq[IP] ## List of ``IP`` instances in the order reported by the system.
        name*: string ## Unique name that identifies the adapter in the system.
        niceName*: string ## Human readable name of the adapter.

    IP* = object
        ## Represents an IP address of an adapter.
        case family*: IpAddressFamily
        of IpAddressFamily.IPv6:
            flowInfo*: uint32
            scopeId*: uint32
        of IpAddressFamily.IPv4:
            discard
        ip*: IpAddress ## IP address
        networkPrefix*: int ## Number of bits of the IP that represent the network.
        niceName*: string ## Human readable name for this IP.

when defined(windows) or defined(nimdoc):
    include ifaddr/windows
elif defined(linux) or defined(maxosx):
    include ifaddr/ifaddrposix
