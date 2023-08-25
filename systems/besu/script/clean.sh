#!/bin/bash

./stop.sh

for i in {{1..3},user} ; do
        rm -rf blkchain-${i}* log-${i}
done

rm -rf workdir/blkchain-user*