const Web3 = require('web3');
const fs = require('fs');
const solc = require('solc');
const path = require('path');
const ethereumUri = 'http://127.0.0.1:8544';

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

// compile contract
const source = fs.readFileSync("./contract/Sample.sol", 'utf8');

let input = {
        language: 'Solidity',
        sources: { 'Sample.sol': { content: source } },
        settings: {
                outputSelection: {
                        '*': { '*': ['*'] }
                }
        }
};

console.log('compiling contract...');
const output = solc.compile(JSON.stringify(input));
console.log('done');
compiledContract = JSON.parse(output);

// unlock account
web3.eth.personal.unlockAccount(accountAddress, accountPassword)
.then((response) => {
        console.log(`${accountAddress} is unlocked`);

        for(let sourceName in compiledContract.contracts)
        for (let contractName in compiledContract.contracts[sourceName]) {
                console.log(contractName);
                var bytecode = compiledContract.contracts[sourceName][contractName].evm.bytecode.object;
                var abi = compiledContract.contracts[sourceName][contractName].abi;

                const MyContract = new web3.eth.Contract(abi);
                console.log('deploying contract...');


                // deploy contract
                web3.eth.estimateGas({ from: `${accountAddress}`, data: `0x${bytecode}` })
                .then((gas) =>{
                        let gasEstimate = gas;
                        console.log(`gasEstimate = ${gasEstimate}`);

                        return MyContract.deploy({
                                data: `0x${bytecode}`,
                        }).send({
                                from: `${accountAddress}`,
                                gas: gasEstimate + 500000,
                                chainId: '0x2d'
                        })
                        .on('error', function(error){ console.log(err); })
                        .on('transactionHash', function(transactionHash){ console.log(transactionHash);})
                        .on('receipt', function(receipt){
                                console.log(receipt.contractAddress); // contains the new contract address
                        })
                        .on('confirmation', function(confirmationNumber, receipt){
                                process.exit(0);
                        });
                })
                .then(function(newContractInstance){
                        console.log(newContractInstance.options.address) // instance with the new contract address
                });
                
                console.log('done');
                // setTimeout(() => process.exit(0), 10000);                    
        }
}).catch((error) => {
        console.log(error);
});