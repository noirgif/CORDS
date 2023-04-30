#!/bin/bash

# read from each node???
for i in {1..3} ; do
    mkdir -p log-${i}
    geth --datadir blkchain-user --nodiscover --networkid 1234 --port 30302 js check_transactions.js
done

