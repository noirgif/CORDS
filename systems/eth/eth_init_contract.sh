#!/bin/bash

log_dir="$(dirname "$0")/setup_log"
file_dir="$(dirname "$0")"
suffix=("" "" "" "")

mkdir -p "$log_dir"

"$file_dir"/eth_init.sh &>"$log_dir"/eth_init.log

echo Starting mining nodes...
# start mining
MINER=1
for i in {1..3}; do
    (cd "$file_dir" && nohup geth --config config/blkchain-"${i}${suffix[$i]}".toml\
     --http --http.api="eth,net,web3,personal,web3" --allow-insecure-unlock js mine.js &) &>>"${log_dir}/${i}.log"
done

# wait for all nodes to start
t=0
for i in {1..3}; do
    while ! ls "$file_dir/blkchain-${i}${suffix[$i]}"/geth.ipc &>/dev/null; do
        sleep 1
        t=$((t + 1))
        if [[ $t -gt 20 ]]; then
            echo "Geth $i didn't start in 20 seconds" >"${log_dir}/error"
            # if the single-block-miner didn't start, delegate to the next one
            if [[ $i -eq $MINER ]]; then
                MINER=$((i + 1))
            fi
            break
        fi
    done
done

# No need to mine a single block since we are sending transaction directly to miner
# echo Mining nodes started, mine a single block

# mine one block to make the miners sync
# for i in {1..3}; do
#     if [[ $i == "${MINER}" ]]; then
#         {
#             pushd .
#             cd $file_dir
#             echo "--- Attaching mining single block script ---"
#             if ! timeout -s KILL 10s geth attach "blkchain-${i}${suffix[$i]}/geth.ipc" <mine_single.js; then
#                 echo "Mining single block script didn't finish in ${MINER} in 10s" | tee "$curr_dir/$log_dir/error"
#                 MINER=$((MINER + 1))
#             fi
#             echo "--- Attached mining single block script ---"
#             popd
#         } >>"${log_dir}/${i}.log"
#     fi
# done

( cd "$file_dir" && node contract/init.js ) &> "$log_dir/contract.log"

( cd "$file_dir" && node contract/write.js ) &>> "$log_dir/contract.log"

# wait some time to let the blocks propagate
sleep 15



# # restart user node
# (cd "$file_dir" && geth --config config/blkchain-user.toml --syncmode=fast js check_block.js &>>"$log_dir/user.log")

"$file_dir"/stop.sh

for i in {1..3}; do
    cp -r blkchain-${i} blkchain-${i}.snapshot
done