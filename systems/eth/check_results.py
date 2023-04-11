#!/bin/env python3

import os
import subprocess
import sys
import json

file_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(file_dir)

if len(sys.argv) == 2:
        path = sys.argv[1]
        file = open(os.path.join(path, 'checker-log'), 'w')
else:
        file = sys.stdout

if os.path.isfile('hash'):
        with open('hash', 'r') as f:
                hash = f.read().strip()

        print("Hash: ", hash, file=file)
else:
        print("No hash file found", file=file)
        exit(1)

# let geth wait for the transaction to be mined

configpath = os.path.join('config', 'blkchain-user.toml')

command = """
let transactionReceiptRetry = (txHash) => eth.getTransactionReceipt(txHash, (err, receipt) => 
        receipt == undefined || Object.keys(receipt).length == 0
            ? setTimeout(() => transactionReceiptRetry(txHash), 500)
            : console.log(JSON.stringify(receipt))
        );

let hash = "{}";
transactionReceiptRetry(hash);
""".format(hash)

with open('get_transaction_temp.js', 'w') as f:
        f.write(command)

try:
        result = subprocess.run(['geth', '--config', configpath, 'js', 'get_transaction_temp.js'], timeout=30, capture_output=True)
        output = result.stdout.decode('utf-8')
        receipt = json.loads(output)
        print('Transaction receipt received', file=file)
except subprocess.TimeoutExpired:
        print("Cannot obtain transaction receipt within 30s", file=file)
except ValueError:
        print("Error: ", output, file=file)
        exit(1)

os.remove('hash')
os.remove('get_transaction_temp.js')



# if successfully mined
# obtain the transaction data using the hash

# stop the nodes so that we can check them individually
# TODO: is it the right way to do this? Should nodes be able to talk to each other
# when the data is not available?
subprocess.run([os.path.join(file_dir, 'stop.sh')])

command = f"""
let hash = "{hash}";
if (eth.getTransactionReceipt(hash) != null) {{
        let tx = eth.getTransaction(hash);
        console.log(JSON.stringify(tx));
}}
"""

with open('get_tx_temp.js', 'w') as f:
        f.write(command)

# TODO: check if the transaction is mined
# TODO: parse the output if we're using attach
# no need for js
for i in range(1, 4):
        print("Testing node {}:".format(i), file=file, end=None)
        miner_config_path = os.path.join('config', f'blkchain-{i}.toml')
        # stop programs and use js, because attach doesn't work
        result = subprocess.run(['geth', '--config', miner_config_path ,'js', 'get_tx_temp.js'], capture_output=True)

        output = result.stdout.decode('utf-8')

        try:
                tx = json.loads(output)
                if tx['input'] == '0x' + 'a' * 16384:
                        print("transaction data verified", file=file)
                else:
                        print("transaction data verification failed", file=file)
        except ValueError:
                print("Error: not a valid transaction", output, file=file)

os.remove('get_tx_temp.js')