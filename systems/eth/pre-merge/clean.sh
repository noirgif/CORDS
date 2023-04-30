#!/bin/bash

cd "$(dirname "$0")"

./stop.sh

for i in {{1..3},user} ; do
        rm -rf blkchain-${i}* log-${i}
done

rm -rf blkchain-user*