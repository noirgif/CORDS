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

for (let sourceName in compiledContract.contracts) {
        for (let contractName in compiledContract.contracts[sourceName]) {
                let abi = compiledContract.contracts[sourceName][contractName].abi;
                let myContractInstance = new web3.eth.Contract(abi, address);
                // console.log(myContractInstance);
                myContractInstance.methods.backup().estimateGas(
                ).then(function (gas) {
                        console.log(gas);
                        return myContractInstance.methods.backup().send({
                                from: accountAddress,
                                gas: gas
                        })
                }).then(function (result) {
                        process.exit(0);
                });
        }
}
