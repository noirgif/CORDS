#!/bin/xonsh

import json, toml

# generate static-nodes.json
nodes = []
for i in range(1, 4):
    pubkey = $(cat config/keys/node-@(i)-pub).strip()
    # remove 0x prefix
    pubkey_stripped = pubkey[2:]
    nodes.append(f"enode://{pubkey_stripped}@127.0.0.1:{30302 + i}")

with open("config/static-nodes.json", "w") as f:
    json.dump(nodes, f, indent=4)


# generate config for each node from template toml
with open("config/node-template.toml") as f:
    template = toml.load(f)

for i in range(1, 4):
    for suffix in ["", ".mp"]:
        template["data-path"] = f"workdir/node-{i}{suffix}"
        template["p2p-port"] = 30302 + i
        template["rpc-http-port"] = 8544 + i
        template["node-private-key-file"]=f"config/keys/node-{i}"
        template["rpc-http-api"]=['ETH', 'NET', 'WEB3', 'ADMIN']

        with open(f"config/node-{i}{suffix}.toml", "w") as f:
            toml.dump(template, f)