#!/bin/bash

cd "$(dirname "$0")"

./clean.sh

rm -f nodes

geth --datadir blkchain-user init config/genesis.json

./stop.sh &>> /dev/null

geth --datadir blkchain-user --nodiscover --networkid 1234  --port 30302 js printenode.js >> nodes

for i in {1..3} ; do
    geth --datadir blkchain-${i} init config/genesis.json
    # create for mining, also print the address for future connection
    geth --datadir blkchain-${i} --nodiscover --networkid 1234  --port $((30302+i)) js printenode.js >> nodes
    cp keys/miner-${i} blkchain-${i}/keystore
done

# put the enode addresses of other nodes into the config file
for i in {1..3} ; do
    geth --datadir blkchain-${i} --nodiscover --networkid 1234  --port $((30302+i)) dumpconfig config/blkchain-${i}.toml
    # connect the user with one of the nodes
    ./rewrite_nodes.py nodes config/blkchain-${i}.toml
done

# put the enode addresses of other nodes into the config file
for i in user; do
    geth --datadir blkchain-${i} --nodiscover --networkid 1234  --port 30302 dumpconfig config/blkchain-${i}.toml
    # connect the user with one of the nodes
    ./rewrite_nodes.py nodes config/blkchain-${i}.toml
done

# for now it is the user that submit the transaction
cp keys/user-{1,2} blkchain-user/keystore


# Because the user cannot submit transaction when there's only the config/genesis block in the network,
# Mine one block
log_dir="$(dirname "$0")/setup_log"
file_dir="$(dirname "$0")"
curr_dir=$(pwd)
suffix=("" "" "" "")

rm -rf "$log_dir"

MINER=1

function startnodes() {
    # start mining nodes
    for i in {1..3} ; do
        mkdir -p "${log_dir}/log-${i}"
        (cd "$file_dir" && nohup geth --config config/blkchain-"${i}${suffix[$i]}".toml --syncmode full js "${!i}" & ) &>> "${log_dir}/log-${i}/geth.log"
    done

    # wait for all nodes to start
    t=0
    for i in {1..3} ; do
        while ! ls "$file_dir/blkchain-${i}${suffix[$i]}"/geth.ipc &> /dev/null ; do
            sleep 1
            t=$((t+1))
            if [[ $t -gt 20 ]] ; then
                echo "Geth $i didn't start in 20 seconds" > "${log_dir}/error"
                # if the single-block-miner didn't start, delegate to the next one
                if [[ $i -eq $MINER ]] ; then
                    MINER=$((i+1))
                fi
                break
            fi
        done
    done
}

startnodes mine.js mine.js mine.js

# mine one block to make the miners sync
for i in {1..3} ; do
    if [[ $i == "${MINER}" ]]; then
        {   cd $file_dir
            echo "--- Attaching mining single block script ---" 
            if ! timeout -s KILL 10s geth attach "blkchain-${i}${suffix[$i]}/geth.ipc" < mine_single.js ; then
                echo "Mining single block script didn't finish in ${MINER} in 10s" | tee "$curr_dir/$log_dir/error"
                MINER=$((MINER+1))
            fi
            echo "--- Attached mining single block script ---"; 
            cd $curr_dir
        } >> "${log_dir}/log-${i}/geth.log"
    fi
done

# wait for other nodes to sync the block
# because the miners will discard blocks in fast sync mode
# "Fast syncing, discarded propagated block number=1 ..."
# Solution, use syncmode full
sleep 10

./stop.sh