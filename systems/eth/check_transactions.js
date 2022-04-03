let transaction_mined = false;
let transaction;

function first_transaction()
{
        for (let i = 0; i < 10; i++) {
                const block = eth.getBlockByNumber(i);
                if (!block)
                        break;
                if (block.transactions.length > 0) {
                        transaction = block.transactions[0];
                        transaction_mined = true;
                        console.log(block.transactions[0]);
                        return;
                }
        }
        setTimeout(first_transaction, 1000);
}

first_transaction();