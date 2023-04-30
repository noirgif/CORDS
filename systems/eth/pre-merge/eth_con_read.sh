#!/bin/bash

file_dir="$(dirname "$0")"
curr_dir=$(pwd)
echo $@

if [[ ! $# -lt 4 ]] ; then
    work_dirs=("" $2 $3 $4) # bash array starts from zero
else
    work_dirs=("" blkchain-{1,2,3})
fi

if [[ $1 == "trace" ]] ; then
    trace_opt="--tracing"
    if [[ !  $# -lt 5 ]] ; then
        trace_dir=$5
    else
        trace_dir="trace"
    fi
    mkdir -p $trace_dir
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
    log_dir="$(dirname "$0")/log"
fi

for i in {1..3} ; do
    rm -rf $log_dir || true
done

mkdir -p "${log_dir}"

MINER=1

# # start mining
# for i in {1..3} ; do
#     #if [[ $i == "${MINER}" ]]; then
#         (cd "$file_dir" && nohup geth --config config/blkchain-"${i}${suffix[$i]}".toml js mine.js & ) &>> "${log_dir}/${i}.log"
#     #else
#     #    nohup geth --datadir blkchain-${i}"${suffix[$i]}" --nodiscover --networkid 1234 --port $((30302+i)) &>> ${i}.log &
#     #fi
# done

# # wait for all nodes to start
# t=0
# for i in {1..3} ; do
#     while ! ls "$file_dir/blkchain-${i}${suffix[$i]}"/geth.ipc &> /dev/null ; do
#         sleep 1
#         t=$((t+1))
#         if [[ $t -gt 20 ]] ; then
#             echo "Geth $i didn't start in 20 seconds" > "${log_dir}/error"
#             # if the single-block-miner didn't start, delegate to the next one
#             if [[ $i -eq $MINER ]] ; then
#                 MINER=$((i+1))
#             fi
#             break
#         fi
#     done
# done

for i in {1..3} ; do
    # check the results
    if [[ "$1" != "debug" ]] ; then
        # start miner node for requests
        (cd "$file_dir" && nohup geth --config "config/blkchain-$i${suffix[$i]}.toml" --http --http.api=eth,net,web3,personal,web3 --allow-insecure-unlock $trace_opt --syncmode snap & ) &>> "${log_dir}/$i.log"
        # wait for miner node to start
        t=0
        while ! ls "$file_dir/blkchain-$i${suffix[$i]}"/geth.ipc &> /dev/null ; do
            sleep 1
            t=$((t+1))
            if [[ $t -gt 20 ]] ; then
                    echo "Geth $i didn't start in 20 seconds" > "${log_dir}/error"
                    break
            fi
        done

    fi
done

for i in {1..3}; do
    node "$file_dir/contract/read.js" "$log_dir" "read-$i.log" "http://127.0.0.1:$((8544+i))" &>> "${log_dir}/eth_con_read-$i.sh.log"
done

"$file_dir/stop.sh" kill

if [[ -n $trace_opt ]] ; then
    for i in {1..3} ; do     
        grep '[trace]' "${work_dirs[$i]}/geth/chaindata/LOG" > "${trace_dir}/${i}.log"
    done
fi