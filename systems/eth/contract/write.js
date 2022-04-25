const Web3 = require('web3');
const fs = require('fs');
const solc = require('solc');
const path = require('path');
const ethereumUri = 'http://127.0.0.1:8545';

let logpath;

if (process.argv.length > 2) {
        logpath = process.argv[2];
} else {
        logpath = '.';
}

let provider = new Web3.providers.HttpProvider(ethereumUri);
let web3 = new Web3(provider);

const accountAddress = 'c0a08062d4979fe49ad3434b0b6c2d6e07e40460';
const accountPassword = '';

if (web3.eth.personal.unlockAccount(accountAddress, accountPassword)) {
        console.log(`${accountAddress} is unlocked`);
} else {
        console.log(`unlock failed, ${accountAddress}`);
}

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

let result = '';

for(let sourceName in compiledContract.contracts) {
    for (let contractName in compiledContract.contracts[sourceName]) {
            let abi = compiledContract.contracts[sourceName][contractName].abi;
            let MyContract = new web3.eth.Contract(abi);
            let myContractInstance = MyContract.at(address);
            // console.log(myContractInstance);
            result = myContractInstance.methods.setValue('a'.repeat(16384)).send({
                from: accountAddress,
            }).then(function(receipt) {  
                console.log(receipt);
                process.exit(0);
            });
    }
}

