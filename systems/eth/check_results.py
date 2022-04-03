#!/bin/env python3

import os
import subprocess
import sys
import json

os.chdir(os.path.dirname(os.path.abspath(__file__)))

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
        print(receipt, file=file)
except subprocess.TimeoutExpired:
        print("Cannot obtain transaction receipt within 30s", file=file)
except ValueError:
        print("Error: ", output, file=file)
        exit(1)

os.remove('hash')
os.remove('get_transaction_temp.js')



# if successfully mined
# obtain the transaction data using the hash

command = """
let hash = "{}";
let tx = eth.getTransaction(hash);
console.log(JSON.stringify(tx));
""".format(hash)

with open('get_tx_temp.js', 'w') as f:
        f.write(command)

for i in range(1, 4):
        print("Testing node {}".format(i), file=file)

        result = subprocess.run(['geth', '--config', configpath, 'js', 'get_tx_temp.js'], capture_output=True)
        os.remove('get_tx_temp.js')

        output = result.stdout.decode('utf-8')

        try:
                tx = json.loads(output)
                if tx['input'] == '0x' + 'a' * 16384:
                        print("Transaction data verified", file=file)
                else:
                        print("Transaction data verification failed", file=file)
                        exit(1)
        except ValueError:
                print("Error: not a valid transaction", output, file=file)
                exit(1)