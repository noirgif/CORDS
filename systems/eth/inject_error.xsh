#!/bin/xonsh

import shutil
import sys
import os

$file_dir='.'

def recover():
        for i in range(1, 4):
                shutil.rmtree(f'blkchain-{i}', ignore_errors=True)
                shutil.copytree(f'blkchain-{i}.snapshot', f'blkchain-{i}')

# make backup
./stop.sh

# Read trace

ERROR_TYPES = {
        'Get': ['NoError', 'ReadIOError',
        'ReadAllZero',
        'ReadCorruption',],
        'Put': [ 'WriteIOError' ],
        'trace': []
}

# format ('operation', 'key accessed')
traced_access = [
        [],
        [],
        [],
]
trace_path = []
result_path = 'inject-results-single'

rm -rf @(result_path)
mkdir -p @(result_path)

if len(sys.argv) >= 2:
        trace_path = sys.argv[1:4]
else:
        trace_path = [*map(lambda x: f'blkchain-{x}/geth/chaindata/LOG', range(1, 4))]

for i in range(3):
        with open(trace_path[i], 'r') as f:
                traces = f.readlines()
                for trace in traces:
                        trace_split = trace.split()
                        if len(trace_split) < 4:
                                continue
                        if trace_split[1] == '[trace]':
                                # remove quotes
                                key = trace_split[3][1:-1]
                                traced_access[i].append((trace_split[2], key))

if not os.path.exists(f'blkchain-3.snapshot'):
        for i in range(1, 4):
                shutil.copytree(f'blkchain-{i}', f'blkchain-{i}.snapshot')
else:
        recover()

# print(traced_access)

$log_dir = 'inject-logs'
rm -rf $log_dir
mkdir -p $log_dir

def decode_access(access):
        decoded_string = bytes.fromhex(access[1])
        newkeystring = ''
        for i in decoded_string:
                if not chr(i).isprintable():
                        newkeystring += '\\x' + hex(i)[2:]
                else:
                        newkeystring += chr(i)
        return (access[0], newkeystring)

# inject error
for ind in range(3):
        time = {}
        i = ind + 1
        # single node test
        if i != 1:
                continue
        for access in traced_access[ind]:
                access_type, key = access

                if access in time:
                        time[access] += 1
                else:
                        time[access] = 1

                for error in ERROR_TYPES[access_type]:
                        print("Checking", *decode_access(access), error, 'in', i)
     
                        # start miner node for requests
                        pushd .
                        cd $file_dir
                        
                        for node in range(1, 4):
                                if node == i:
                                        bash -c $(echo nohup geth --config config/blkchain-@(i).toml --http --http.api=eth,net,web3,personal,web3 --allow-insecure-unlock --injectederror @(error) --injectederrorkey @(key) --injectederrortime @(time[access]) '&>>' $log_dir/@(i).log '&')
                                else:
                                        # single node test
                                        continue
                                        # start other nodes normally
                                        bash -c $(echo nohup geth --config config/blkchain-@(node).toml '&>>' $log_dir/@(node).log '&')



                        popd

                        # wait for miner node to start
                        t = 0
                        start = True
                        for node in range(1, 4):
                                # single node test
                                if node != i:
                                        continue
                                while not !(ls blkchain-@(node)/geth.ipc &> /dev/null ):
                                        sleep 1
                                        t += 1
                                        if t >= 20:
                                                echo "Geth" @(node) "didn't start in 20 seconds" > $log_dir/error
                                                start = False
                                                break

                        # read from node
                        if start:
                                node $file_dir/contract/read.js $log_dir &>> $log_dir/eth_con_read.sh.log

                        mkdir -p @(result_path)/n@(i)_@(key)_t@(time[access])_@(error)
                        cp blkchain-@(i)/geth/chaindata/LOG @(result_path)/n@(i)_@(key)_t@(time[access])_@(error)/chaindata-log 
                        mv $log_dir/* @(result_path)/n@(i)_@(key)_t@(time[access])_@(error)

                        $file_dir/stop.sh kill &> /dev/null
                        # restore backup
                        # input('Paused...')
                        recover()


directories = ['error', 'wrong', 'normal']

mkdir -p $log_dir/@(directories)
errors = $(ls $log_dir).split()
for directory in directories:
    errors.remove(directory)

pushd .
cd $log_dir

for error in errors:
    if $(cat @(error)/read.log 2> /dev/null) == 'Contract data validated':
        mv @(error) normal
    elif ![ls @(error)/error &> /dev/null]:
        mv @(error) error
    else:
        mv @(error) wrong

popd