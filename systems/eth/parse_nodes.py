#!/bin/env python3

from sys import stdin

print("[")

addr = []
for (i, line) in enumerate(stdin):
        # don't know why geth js prints random address for enode, fix it
        addr.append('"' + line.split("@")[0] + "@127.0.0.1:" + str(30303 + i) + '?discport=0"')
print(",\n".join(addr))

print("]")