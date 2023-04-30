#!/bin/bash

rm -rf reproduce
mkdir -p reproduce

cp -R blkchain-user reproduce

if [ -z "$1" ]; then
    echo "Usage: $0 <result-path>"
    exit 1
fi

result_path="$1"

for i in {1..3} ; do
    cp -R $result_path/blkchain-$i reproduce/
done

for i in {1..3} ; do
    nohup geth --config config/blkchain-"${i}".toml --datadir reproduce/blkchain-$i js mine.js > reproduce/log-$i &
done

geth --config config/blkchain-user.toml --datadir reproduce/blkchain-user console

./stop.sh