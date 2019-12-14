#!/bin/bash

echo Removing containers, data and logs ... need supervisor privilege
cd tidb-docker-compose || exit 1
yes | docker-compose rm -s
for f in workdir/* ; do 
    sudo rm -rf "$f"/{data,logs}/*
done
cd ..

docker-compose -f tidb-docker-compose/generated-docker-compose.yml up -d

# Spin until all TiKV instances are online and ready
wait_time=0
while true ;
do
	probe=$(pd-ctl region)
	stores=$(echo $probe | grep -o store_id | wc -l)
	if [ $stores -gt 3 ] && ! echo $probe | grep pending > /dev/null ; then
		break
	fi
	sleep 1
	wait_time=$((wait_time + 1))
done

echo "Waited $wait_time second(s)"

cd goclient && go run insert.go && cd ..

docker-compose -f tidb-docker-compose/generated-docker-compose.yml down
sudo chown -R $USER:$USER tidb-docker-compose/workdir

echo Backing up everything ...
for f in tidb-docker-compose/workdir/* ; do
	sudo rm -rf $f/data.snapshot
	cp -r $f/data $f/data.snapshot
	echo $(basename $f)
done
