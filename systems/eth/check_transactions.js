for (let i = 1; i < 100; ++i)
{
        let block = eth.getBlockByNumber(i);
        if (block === null)
                break;
        if (block.transactions.length > 0)
        {
                block.transactions.forEach(element => {
                        let tx = eth.getTransaction(element);
                        console.log(JSON.stringify(tx));
                });
        }
}