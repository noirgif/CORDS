
let transactionReceiptRetry = (txHash) => eth.getTransactionReceipt(txHash, (err, receipt) => 
        receipt == undefined || Object.keys(receipt).length == 0
            ? setTimeout(() => transactionReceiptRetry(txHash), 500)
            : console.log(JSON.stringify(receipt))
        );

let hash = "0xd010f717480baa67241f59d647f220f70671153126a79d7bf88622138ce703ab";
transactionReceiptRetry(hash);
