#!/bin/bash

./stop.sh

while pgrep geth > /dev/null ; do
    sleep 1
done

rm -f nodes

for i in {1..3} ; do
    geth --datadir blkchain-${i} init genesis.json
    # create for mining, also print the address for future connection
    geth --datadir blkchain-${i} --nodiscover --networkid 1234 --port $((30302+i)) js printenode.js >> nodes
    cp keys/miner-${i} blkchain-${i}/keystore
done

# put the enode addresses of other nodes into the config file
for i in {1..3} ; do
    ./parse_nodes.py < nodes > blkchain-${i}/geth/static-nodes.json
done

# connect the user with one of the nodes
./parse_nodes.py < nodes > blkchain-user/geth/static-nodes.json && \
rm nodes

# restart user node
geth --datadir blkchain-user --nodiscover --networkid 1234 --port 30302

./start.sh

