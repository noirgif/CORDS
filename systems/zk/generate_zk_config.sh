#!/bin/bash

# set up the config files
# will be run in zk_init.sh

for i in {0..2} ; do
	read -d '' -r configs <<- _EOF_
	tickTime=2000
	dataDir=$PWD/workload_dir$i.mp
	clientPort=2182
	initLimit=5
	syncLimit=2
	server.1=127.0.0.2:2888:3888
	server.2=127.0.0.3:2889:3889
	server.3=127.0.0.4:2890:3890
	preAllocSize=40
	_EOF_
	echo "$configs" > "zoo$i.cfg"
done