#!/bin/xonsh

import shutil
import sys
import os

$file_dir='.'

def recover():
        shutil.rmtree(f'workdir/sepolia', ignore_errors=True)
        shutil.copytree(f'workdir/sepolia.snapshot', f'workdir/sepolia')

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
times = [{}, {}, {}]
trace_path = []
result_path = 'results/spl-results-single'

rm -rf @(result_path)
mkdir -p @(result_path)

if len(sys.argv) >= 2:
        trace_path = [sys.argv[1]]
else:
        trace_path = ['workdir/sepolia/geth/chaindata/LOG']

# move traces out to avoid forever lengthening

for i in range(1):
        with open(trace_path[i], 'r') as f:
                traces = f.readlines()
                for trace in traces:
                        if trace.startswith('='):
                                traced_access[i] = []
                                continue
                        trace_split = trace.split()
                        if len(trace_split) < 4:
                                continue
                        if trace_split[1] == '[trace]':
                                # remove quotes
                                key = trace_split[3][1:-1]
                                time = times[i][key] if key in times[i] else 1
                                traced_access[i].append((time, trace_split[2], key))
        traced_access[i] = sorted(traced_access[i], key=lambda x: x[0]) # sort with regard to time

if not os.path.exists(f'workdir/sepolia.snapshot'):
        shutil.copytree(f'workdir/sepolia', 'workdir/sepolia.snapshot')
else:
        recover()

# print(traced_access)

$log_dir = 'spl-inject-logs'
rm -rf $log_dir
mkdir -p $log_dir

def decode_access(access):
        time, trace_split, key = access
        decoded_string = bytes.fromhex(key)
        newkeystring = ''
        for i in decoded_string:
                if not chr(i).isprintable():
                        newkeystring += '\\x' + hex(i)[2:]
                else:
                        newkeystring += chr(i)
        return (time, trace_split, newkeystring)

# inject error
for ind in range(1):
        time = times[ind]
        i = ind + 1
        # single node test
        if i != 1:
                continue
        for access in traced_access[ind]:
                this_time, access_type, key = access

                for error in ERROR_TYPES[access_type]:
                        print("Checking", *decode_access(access), error)
     
                        # start miner node for requests
                        
                        scripts/run_sepolia.xsh inject --injectederror @(error) --injectederrorkey @(key) --injectederrortime @(this_time) &> $log_dir/geth.log &


                        # wait for miner node to start
                        t = 0
                        start = True
                        for node in range(1):
                                # single node test
                                if node != i:
                                        continue
                                while not !(ls workdir/sepolia/geth.ipc &> /dev/null ):
                                        sleep 1
                                        t += 1
                                        if t >= 20:
                                                echo "Geth" @(node) "didn't start in 20 seconds" > $log_dir/error
                                                start = False
                                                break

                        # instead of IO, just let it run for a while
                        if start:
                                sleep 1m
                                $file_dir/stop.sh &> /dev/null

                        mkdir -p @(result_path)/n@(i)_@(key)_t@(this_time)_@(error)
                        cp workdir/sepolia/geth/chaindata/LOG @(result_path)/n@(i)_@(key)_t@(this_time)_@(error)/chaindata-log 
                        mv $log_dir/* @(result_path)/n@(i)_@(key)_t@(this_time)_@(error)

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