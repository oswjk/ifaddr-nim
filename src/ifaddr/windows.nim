# Required for IP_ADAPTER_ADDRESSES_LH
{.emit:"""/*INCLUDESECTION*/
#include <winsock2.h>
""".}

import winlean
import os

import private/utils


type
    IP_ADAPTER_ADDRESSES_LH {.importc, header: "<iphlpapi.h>".} = object
        Next: ptr IP_ADAPTER_ADDRESSES_LH
        AdapterName: cstring
        FirstUnicastAddress: ptr IP_ADAPTER_UNICAST_ADDRESS_LH
        Description: WideCString
        FriendlyName: WideCString

    IP_ADAPTER_UNICAST_ADDRESS_LH {.importc, header: "<iphlpapi.h>".} = object
        Next: ptr IP_ADAPTER_UNICAST_ADDRESS_LH
        Address: SOCKET_ADDRESS
        OnLinkPrefixLength: uint8

    SOCKET_ADDRESS {.importc, header: "<winsock2.h>"} = object
        lpSockaddr: ptr SockAddr
        iSockaddrLength: cint

const
    ERROR_BUFFER_OVERFLOW = 0x6f

proc GetAdaptersAddresses(family: ULONG, flags: ULONG, reserved: pointer, adapterAddresses: ptr IP_ADAPTER_ADDRESSES_LH, size: ptr ULONG): ULONG {.stdcall, dynlib: "iphlpapi.dll", importc.}

proc getAdapters*(): seq[Adapter] =
    result = @[]

    var
        bufsz: ULONG = 15*1024
        rc: DWORD = ERROR_BUFFER_OVERFLOW
        buffer: seq[byte]

    while rc == ERROR_BUFFER_OVERFLOW:
        buffer.setLen(bufsz)
        rc = GetAdaptersAddresses(AF_UNSPEC, 0, nil,
            cast[ptr IP_ADAPTER_ADDRESSES_LH](addr buffer[0]), addr bufsz)

    if rc != 0:
        raiseOSError(rc.OSErrorCode, "GetAdaptersAddresses")

    let first = cast[ptr IP_ADAPTER_ADDRESSES_LH](addr buffer[0])
    var curr = first
    while curr != nil:
        let name = $curr.AdapterName
        let niceName = $curr.Description
        var ips: seq[IP] = @[]

        var currAddr = curr.FirstUnicastAddress
        while currAddr != nil:
            var
                ip: IpAddress
                scopeId: uint32
                flowInfo: uint32
            fromSockAddrPtr(currAddr.Address.lpSockaddr, ip, flowInfo, scopeId)
            case ip.family
            of IpAddressFamily.IPv6:
                ips.add(IP(family: IpAddressFamily.IPv6,
                    flowInfo: flowInfo,
                    scopeId: scopeId,
                    ip: ip,
                    networkPrefix: currAddr.OnLinkPrefixLength.int,
                    niceName: $curr.FriendlyName))
            of IpAddressFamily.IPv4:
                ips.add(IP(family: IpAddressFamily.IPv4,
                    ip: ip,
                    networkPrefix: currAddr.OnLinkPrefixLength.int,
                    niceName: $curr.FriendlyName))
            currAddr = currAddr.Next

        result.add(Adapter(ips: ips, name: name, niceName: niceName))

        curr = curr.Next
