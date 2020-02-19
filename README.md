# ifaddr - Enumerate IP addresses on the local network adapters

This is a Nim port of a Python package of the same name. See the original [here](https://github.com/pydron/ifaddr).

Check the example code in `tests/test1.nim`. It should output something like the following:

```
IPs of network adapter lo
  127.0.0.1/8
  00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:01/128
IPs of network adapter wlp2s0
  192.168.0.101/24
  FE:80:00:00:00:00:00:00:65:93:59:F2:33:F0:AB:33/64
```
