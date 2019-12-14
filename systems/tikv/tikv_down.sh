#!/bin/bash

# set up the cluster
docker-compose -f tidb-docker-compose/generated-docker-compose-mp.yml down
# echo tidb-docker-compose/workdir/*/data.mp | xargs -n 1 fusermount -u
# echo tidb-docker-compose/workdir/*/data.mp | xargs rm -rf
