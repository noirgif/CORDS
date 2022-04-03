#!/bin/env python3

import toml
import sys
import os
import re

curpath = os.path.dirname(os.path.abspath(__file__))

if len(sys.argv) < 3:
    print("Usage: %s <node_file> <config_file>" % sys.argv[0])
    exit(1)

config_file = os.path.join(curpath, sys.argv[2])

config = toml.load(config_file)
# print(config['Node.P2P']['StaticNodes'])     #

nodes = []

with open(sys.argv[1], 'r') as node_list_file:
    nodes = list(map(str.strip, node_list_file.readlines()))

rewrite_nodes = []

for node in nodes:
    # replace ip with 127.0.0.1 because the user cannot connect to them using the public ip(it's behind a NAT)
    node = re.sub(r'\d+\.\d+\.\d+\.\d+', '127.0.0.1', node)
    rewrite_nodes.append(node)

config['Node']['P2P']['StaticNodes'] = rewrite_nodes

with open(config_file, 'w') as config_file:    # save
    toml.dump(config, config_file)


# write another version with .mp as datadir
path = re.sub(r'\.toml$', '.mp.toml', sys.argv[2].strip())
config_file = os.path.join(curpath, path)

config['Node']['DataDir'] = config['Node']['DataDir'] + '.mp'
with open(config_file, 'w') as config_file:    # save
    toml.dump(config, config_file)
