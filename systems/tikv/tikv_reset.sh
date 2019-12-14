#!/bin/bash

# set up the cluster
docker-compose -f tidb-docker-compose/generated-docker-compose-mp.yml down
for i in tidb-docker-compose/workdir/tikv{0..2}/data.mp ;
do
	sudo fusermount -u $i
done
for i in tidb-docker-compose/workdir/tikv{0..2}/data.mp ;
do
	sudo rm -rf $i
done
