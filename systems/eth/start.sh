#!/bin/bash

# start mining
for i in {1..3} ; do
    mkdir -p log-${i}
    nohup geth --mine --miner.threads 1 --datadir blkchain-${i} --nodiscover --networkid 1234 --port $((30302+i)) &>> log-${i}/geth.log &
done

# wait for all nodes to start
for i in {1..3} ; do
    while ! ls blkchain-${i}/geth.ipc &> /dev/null ; do
        sleep 1
    done
done

for i in {1..3} ; do
    geth --datadir blkchain-${i} attach < mine.js > /dev/null
done

#geth --datadir blkchain-user --nodiscover --networkid 1234 --port 30302 js transaction-1.js