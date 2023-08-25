#!/bin/bash

./stop.sh

cd "$(dirname "$0")"

for i in {{1..3},user} ; do
        rm -rf blkchain-${i}
        if [[ -d blkchain-${i}.snapshot ]] ; then
                cp -R blkchain-${i}.snapshot blkchain-${i}
        fi
done