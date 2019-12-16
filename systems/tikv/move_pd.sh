#!/bin/bash
# To copy the state and logs of the PDs as well
# called with $0 log_dir

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
LOG_DIR=$1

for pd in "$DIR"/tidb-docker-compose/workdir/pd* ; do
    pdx=$(basename "$pd")
    L="$LOG_DIR/log-$pdx"
    mkdir -p $L
    cp -rf "$pd/logs/$pdx.log" "$L"
done
exit 0
