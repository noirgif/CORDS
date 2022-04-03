#!/bin/bash

file_dir="$(dirname "$0")"
curr_dir=$(pwd)
echo $@

if [[ ! $# -lt 4 ]] ; then
    work_dirs=("" $2 $3 $4) # bash array starts from zero
else
    work_dirs=("" blkchain-{1,2,3})
fi

rm -rf "$file_dir"/blkchain-user.snapshot > /dev/null || true
cp -R "$file_dir"/blkchain-user "$file_dir"/blkchain-user.snapshot

if [[ "$1" == "noerrfs" || "$1" == "debug" ]] ; then
    suffix=("" "" "")
else
    for i in {1..3} ; do
        echo -n "${work_dirs[$i]}"
        if [[ ${work_dirs[$i]} == *".mp" ]] ; then
            echo " mp"
            suffix[$i]=".mp"
        else
            echo " no mp"
            suffix[$i]=""
        fi
    done
fi

if [[ -n "$5" ]] ; then
    log_dir="$5"
else
    log_dir="$(dirname "$0")"
fi

for i in {1..3} ; do
    rm -rf $log_dir/log-$i || true
done

# if [[ "$1" != "debug" ]] ; then
    # if debug is provided, let the debugger to send the transaction
# (cd "$file_dir" && geth --config config/blkchain-user.toml js send_transaction.js > "hash" )
# fi

MINER=1

# start mining
for i in {1..3} ; do
    mkdir -p "${log_dir}/log-${i}"
    #if [[ $i == "${MINER}" ]]; then
        (cd "$file_dir" && nohup geth --config config/blkchain-"${i}${suffix[$i]}".toml js mine.js & ) &>> "${log_dir}/log-${i}/geth.log"
    #else
    #    nohup geth --datadir blkchain-${i}"${suffix[$i]}" --nodiscover --networkid 1234 --port $((30302+i)) &>> log-${i}/geth.log &
    #fi
done

# wait for all nodes to start
t=0
for i in {1..3} ; do
    while ! ls "$file_dir/blkchain-${i}${suffix[$i]}"/geth.ipc &> /dev/null ; do
        sleep 1
        t=$((t+1))
        if [[ $t -gt 20 ]] ; then
            echo "Geth $i didn't start in 20 seconds" > "${log_dir}/error"
            # if the single-block-miner didn't start, delegate to the next one
            if [[ $i -eq $MINER ]] ; then
                MINER=$((i+1))
            fi
            break
        fi
    done
done

# mine one block to make the miners sync
# for i in {1..3} ; do
#     if [[ $i == "${MINER}" ]]; then
#         {   cd $file_dir
#             echo "--- Attaching mining single block script ---" 
#             if ! timeout -s KILL 10s geth attach "blkchain-${i}${suffix[$i]}/geth.ipc" < mine_single.js ; then
#                 echo "Mining single block script didn't finish in ${MINER} in 10s" | tee "$curr_dir/$log_dir/error"
#                 MINER=$((MINER+1))
#             fi
#             echo "--- Attached mining single block script ---"; 
#             cd $curr_dir
#         } >> "${log_dir}/log-${i}/geth.log"
#     fi
# done

if [[ "$1" != "debug" ]] ; then
    # if debug is provided, let the debugger to send the transaction
    (cd "$file_dir" && geth --config config/blkchain-user.toml js send_transaction.js > "hash" )
fi

# check the results
if [[ "$1" != "debug" ]] ; then
    # if debug is provided, let the debugger to send the transaction
    time $file_dir/check_results.py | tee "${log_dir}/checker.log"
    rm -rf "$file_dir"/blkchain-user
    cp -R "$file_dir"/blkchain-user.snapshot "$file_dir"/blkchain-user
fi


"$file_dir"/stop.sh kill
