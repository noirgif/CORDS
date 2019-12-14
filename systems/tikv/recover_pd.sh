#!/bin/bash

echo Recovering PDs ...
for f in tidb-docker-compose/workdir/pd* ; do
	sudo rm -rf $f/data 
	cp -r $f/data.snapshot $f/data 
	echo $(basename $f)
done
