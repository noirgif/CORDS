#!/usr/bin/env python3

import itertools
import json
import os
import re
import shutil
import subprocess
import signal
from pathlib import Path
from time import sleep
import time
from typing import List, Tuple
from terminals import run_in_curses

from web3 import Web3, IPCProvider


def is_display_available():
    try:
        os.environ['DISPLAY']
        return True
    except KeyError:
        return False


TERMINAL = False

os.chdir(Path(__file__).parent)

DEVNET_PATH = Path('/dev/shm/devnet')
if 'DEVNET_PATH' in os.environ:
    DEVNET_PATH = Path(os.environ['DEVNET_PATH']).absolute()

CONFIG_SUFFIX='-work'

CONFIG_YML = None
with open(f'prysm{CONFIG_SUFFIX}.yml', 'r') as f:
    CONFIG_YML = f.read()

GENESIS_JSON = None
with open(f'genesis{CONFIG_SUFFIX}.json', 'r') as f:
    GENESIS_JSON = f.read()

NUM_NODES = 3

NODE_PATH: dict[int, Path] = {}
GETH_PATH: dict[int, Path] = {}
KEY_DIR = Path('keys-posdevnet').absolute()

PEERS: List[str] = []
GETH_PEERS: List[str] = []

for i in range(1, NUM_NODES + 1):
    NODE_PATH[i] = DEVNET_PATH / f'node{i}'
    GETH_PATH[i] = NODE_PATH[i] / 'geth'

# read addresses from keys
ADDRESSES = []
for i in range(1, NUM_NODES + 1):
    with open(Path('keys-posdevnet') / f'key{i}.json', 'r') as f:
        ADDRESSES.append(json.load(f)['address'])


def setup():
    DEVNET_PATH.mkdir(exist_ok=True)
    os.chdir(DEVNET_PATH)

    with open('config.yml', 'w') as f:
        f.write(CONFIG_YML)

    with open('genesis.json', 'w') as f:
        f.write(GENESIS_JSON)


def setup_node(no=1):
    node_path = NODE_PATH[no]
    geth_path = GETH_PATH[no]

    node_path.mkdir(exist_ok=True)

    print(f"Initializing node {no}...")

    subprocess.run(['geth', '--datadir=' + str(geth_path), '--db.engine=pebble',
                   'init', str(DEVNET_PATH / 'genesis.json')], capture_output=True, text=True)

    # copy key to the geth directory
    shutil.copy(KEY_DIR / f'key{no}.json', geth_path / 'keystore' / 'key.json')

    with open(node_path / "jwt.hex", 'w') as f:
        f.write(subprocess.run(['openssl', 'rand', '-hex', '32'],
                capture_output=True, text=True).stdout.strip())


def http_port(no=1):
    return 8545 + (no - 1) * 3


def ws_port(no=1):
    return 8546 + (no - 1) * 3


def authrpc_port(no=1):
    return 8547 + (no - 1) * 3


def peer_port(no=1):
    return 30303 + (no - 1)


def beacon_port(no=1):
    return 4000 + (no - 1)


def validator_grpc_port(no=1):
    return 7500 + (no - 1)


def validator_rpc_port(no=1):
    return 7000 + (no - 1)


def retry(func, *args, **kwargs):
    for delay in [1, 2, 4]:
        try:
            result = func(*args, **kwargs)
            if result:
                return result
        except Exception as e:
            print(e)
        sleep(delay)
    return func(*args, **kwargs)


def start_node(no=1):
    """Starts a node with the given number
    Returns the processes for geth, beacon and validator"""
    node_path = NODE_PATH[no]
    geth_path = GETH_PATH[no]

    geth_cmd = ['geth', '--http', '--http.api', "eth,engine", '--datadir=' + str(geth_path), '--allow-insecure-unlock', '--unlock=0x' + ADDRESSES[no - 1], '--password=/dev/null', '--nodiscover', '--syncmode=full', '--authrpc.jwtsecret', str(
        node_path / "jwt.hex"), '--port', str(peer_port(no)), '--http.port', str(http_port(no)), '--ws.port', str(ws_port(no)), '--authrpc.port', str(authrpc_port(no)), '--db.engine=pebble', '--mine', '--miner.etherbase=' + ADDRESSES[no - 1]]

    print('Starting Geth for node', no, ':', ' '.join(geth_cmd))
    geth_log = open(node_path / 'geth.log', 'w')
    if not TERMINAL:
        geth_proc = subprocess.Popen(
            geth_cmd, stdout=geth_log, stderr=geth_log, text=True)
    else:
        geth_proc = subprocess.Popen(
            ['xfce4-terminal', '-e', ' '.join(geth_cmd)])

    # Add geth node to peers list and connect it to existing nodes
    ipc_path = geth_path / 'geth.ipc'
    retry(lambda: ipc_path.exists())
    node = Web3(IPCProvider(str(ipc_path)))
    for peer in GETH_PEERS:
        node.geth.admin.add_peer(peer)
    enodeUrl = node.geth.admin.node_info()['enode']
    GETH_PEERS.append(enodeUrl)

    # Before starting the beacon node, we need to generate the genesis state for it
    if not (node_path / 'genesis.ssz').exists():
        print('Generating genesis state for node', no, '...')
        retry(lambda: subprocess.run(['prysmctl', 'testnet', 'generate-genesis', '--num-validators=64', '--output-ssz=' + str(node_path / 'genesis.ssz'), '--chain-config-file=' + str(
            DEVNET_PATH / 'config.yml'), '--override-eth1data=true', '--geth-genesis-json-in=' + str(DEVNET_PATH / 'genesis.json'),  '--geth-genesis-json-out=' + str(DEVNET_PATH / 'genesis.json')]).returncode == 0)
        # print current unix timestamp
        print('Current unix timestamp:', int(time.time()))

    peers_argument = itertools.chain.from_iterable(
        [['--peer', peer] for peer in PEERS])

    beacon_cmd = ['beacon-chain', '--datadir=' + str(node_path / 'beacondata'), "--interop-eth1data-votes", '--min-sync-peers=0', '--genesis-state=' + str(node_path / 'genesis.ssz'), '--bootstrap-node=', '--chain-config-file=' + str(DEVNET_PATH / 'config.yml'), '--config-file=' + str(
        DEVNET_PATH / 'config.yml'), '--chain-id=32382', '--execution-endpoint=http://localhost:' + str(authrpc_port(no)), '--accept-terms-of-use', '--jwt-secret=' + str(node_path / "jwt.hex"), '--rpc-port', str(beacon_port(no)), '--no-discovery', *peers_argument]

    beacon_log = open(node_path / 'beacon.log', 'w')
    print('Starting beacon node', no, ':', ' '.join(beacon_cmd))
    if not TERMINAL:
        beacon_proc = subprocess.Popen(
            beacon_cmd, stdout=beacon_log, stderr=beacon_log, text=True)
    else:
        beacon_proc = subprocess.Popen(
            ['xfce4-terminal', '-e', ' '.join(beacon_cmd)])

    validator_proc = None

    if no == 1:
        validator_cmd = ['validator', '--datadir=' + str(node_path / 'validatordata'), '--accept-terms-of-use', '--interop-num-validators=64', '--interop-start-index=0', '--force-clear-db', '--chain-config-file=' + str(
            DEVNET_PATH / 'config.yml'), '--config-file=' + str(DEVNET_PATH / 'config.yml'), '--grpc-gateway-port=' + str(validator_grpc_port(no)), '--rpc-port=' + str(validator_rpc_port(no)), '--beacon-rpc-provider=localhost:' + str(beacon_port(no))]

        validator_log = open(node_path / 'validator.log', 'w')
        print('Starting validator node', no, ':', ' '.join(validator_cmd))
        if TERMINAL:
            validator_proc = subprocess.Popen(
                ['xfce4-terminal', '-e', ' '.join(validator_cmd)])
        else:
            validator_proc = subprocess.Popen(
                validator_cmd, stdout=validator_log, stderr=validator_log, text=True)

    # if it is the first node, we add it to the peers list
    def get_peer():
        peer_result = subprocess.run(
            ['curl', 'localhost:8080/p2p'], capture_output=True, text=True).stdout.strip()
        # example peer:
        # bootnode=[]
        # self=/ip4/172.17.195.116/tcp/13000/p2p/16Uiu2HAkzFu54hZr8ZB4mn9ZiKwc52bARDJdJMtnqbUDf5fMNmWk
        # extract '/ip4/...' part
        pattern = r"/ip4/[a-zA-Z0-9/\.]+"
        match = re.search(pattern, peer_result)

        if match:
            ip4_part = match.group()
            return ip4_part

    peer = retry(get_peer)
    if peer:
        PEERS.append(peer)
    else:
        print("Could not get peer")
        return ()

    return geth_proc, beacon_proc, validator_proc


def send_interrupt(*procs: Tuple[List[subprocess.Popen]]):
    for proc in itertools.chain.from_iterable(procs):
        if proc is None:
            continue
        os.kill(proc.pid, signal.SIGINT)


def check_error(*procs: Tuple[List[subprocess.Popen]] | Tuple[dict[subprocess.Popen, int]]):
    for ind, proc_group in enumerate(procs):
        for proc in proc_group:
            if proc is None:
                continue
            name = 'Node ' + str(ind) + ' ' + proc.args[0]
            if proc.returncode != 0:
                print(f"{name} ended with error")
            else:
                print(f"{name} ended successfully")


if __name__ == '__main__':
    os.system(f"killall -SIGINT validator geth beacon-chain")
    os.system(f"rm -rf {DEVNET_PATH}")

    setup()
    setup_node(1)
    setup_node(2)

    clients = start_node(1)
    clients2 = start_node(2)

    print("Nodes started, waiting x seconds...")

    if not TERMINAL:
        run_in_curses([['tail', '-f', str(NODE_PATH[1] / 'geth.log')],
                      ['tail', '-f', str(NODE_PATH[1] / 'beacon.log')],
                      ['tail', '-f', str(NODE_PATH[1] / 'validator.log')]],
                      [['tail', '-f', str(NODE_PATH[2] / 'geth.log')],
                       ['tail', '-f', str(NODE_PATH[2] / 'beacon.log')]])
    else:
        input("Press enter to continue...")

    check_error(clients, clients2)
