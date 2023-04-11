#!/bin/xonsh

# Recover the state and set up for debuggin in VS Code

import json
import os
import shutil
import re
import ast

def recover():
        for i in range(1, 4):
                shutil.rmtree(f'blkchain-{i}', ignore_errors=True)
                shutil.copytree(f'blkchain-{i}.snapshot', f'blkchain-{i}')

geth_path = '/home/noirgif/Documents/work/blockchain/eth/go-ethereum'
launchjson_path = os.path.join(geth_path, '.vscode/launch.json')

if len($ARGS) < 2:
    print(f"Usage: {$ARG0} <error folder path>")
    exit(1)
else:
    error_folder = $ARG1

error = os.path.basename(error_folder)
error_list = error.split('_')

node = int(error_list[0][1:])
key = error_list[1]
error_time = int(error_list[2][1:])
error_type = error_list[3]


recover()

with open(launchjson_path, 'r') as f:
    fc = f.read()
    # remove // comments
fc = re.sub(r'//.*', '', fc)
launchjson = ast.literal_eval(fc)
launchjson['configurations'][0]['args'] = [
    f"--config=config/blkchain-{node}.toml",
    "--http",
    "--http.api=eth,net,web3,personal,web3",
    "--allow-insecure-unlock",
    "--injectederror",
    error_type,
    "--injectederrorkey",
    key,
    "--injectederrortime",
    str(error_time),
]

with open(launchjson_path, 'w') as f:
    json.dump(launchjson, f, indent=8)