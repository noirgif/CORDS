const Web3 = require('web3');
const fs = require('fs');
const solc = require('solc');
const path = require('path');
let ethereumUri = 'http://127.0.0.1:8545';

let logpath = '.';
let log_file = 'read.log';

if (process.argv.length > 2) {
        logpath = process.argv[2];
}

if (process.argv.length > 3) {
        log_file = process.argv[3];
}

if (process.argv.length > 4) {
        ethereumUri = process.argv[4];
}

let provider = new Web3.providers.HttpProvider(ethereumUri);
let web3 = new Web3(provider);

const accountAddress = 'c0a08062d4979fe49ad3434b0b6c2d6e07e40460';
const accountPassword = '';



// compile contract
const source = fs.readFileSync(path.join(__dirname, "Sample.sol"), 'utf8');

// new solc things
let input = {
        language: 'Solidity',
        sources: {
                'Sample.sol': {
                        content: source
                }
        },
        settings: {
                outputSelection: {
                        '*': {
                                '*': ['*']
                        }
                }
        }
};

const output = solc.compile(JSON.stringify(input));
compiledContract = JSON.parse(output);

const address = '0xbfc29b202C163ccB6fF64a5b1925569801d7aA44';
web3.eth.defaultAccount = `0x${accountAddress}`;

for (let sourceName in compiledContract.contracts) {
        for (let contractName in compiledContract.contracts[sourceName]) {
                let abi = compiledContract.contracts[sourceName][contractName].abi;
                let myContractInstance = new web3.eth.Contract(abi, address);
                // console.log(myContractInstance);
                myContractInstance.methods.getValue().call()
                        .then(function (result) {
                                checker_logpath = path.join(logpath, log_file);

                                if (result == 'a'.repeat(16384)) {
                                        fs.writeFileSync(checker_logpath, 'Contract data validated');
                                } else if (result == 'Hello, world!') {
                                        fs.writeFileSync(checker_logpath, 'Contract data old');
                                } else {
                                        fs.writeFileSync(checker_logpath, 'Contract data invalid');
                                        fs.writeFileSync(checker_logpath, 'Got: ' + result);
                                }

                                process.exit(0);
                        });
        }
}

