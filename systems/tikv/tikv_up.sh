#!/bin/bash

# set up the cluster
rm -rf tidb-docker-compose/workdir/*/logs/*
if ! [ $1 ] ; then
	echo Starting original...
    	docker-compose -f tidb-docker-compose/generated-docker-compose.yml up -d
else
	# recover the PD
	# ./recover_pd.sh
	# replace the path in docker-compose
	sed -E "s|workdir/tikv0/data[^:]*|$1|" tidb-docker-compose/generated-docker-compose.yml | \
	sed -E "s|workdir/tikv1/data[^:]*|$2|" | \
	sed -E "s|workdir/tikv2/data[^:]*|$3|" > tidb-docker-compose/generated-docker-compose-mp.yml
	docker-compose -f tidb-docker-compose/generated-docker-compose-mp.yml up -d
fi

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
	if [ $wait_time -gt 60 ] ; then
		echo Waited past 60s, break...
		break
	fi
done

echo "Waited $wait_time second(s)"


