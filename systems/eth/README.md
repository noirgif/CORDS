# Setting up Geth nodes

1. Initialize
    a. Start up a chain with dev account in 1st instance
    b. Initialize other 3 chains with this blockchain
2. Run workload

    a. Start another

    b. Peer with one of the nodes

    c. Start a transaction
    * how to mine iff only transactions are pending confirmation
    * <s>Not broadcasted</s>
        because of https://github.com/ethereum/go-ethereum/issues/21385
        *But it works when starting in mining mode, might not be the problem*
        *Retry running the code by piping into attach mode(worked once), or...*
        * Just find a way to stop mining
        * <s>Check `eth.pendingTransaction` once in a while</s> use get transcript
         * Promises/async does not work as geth is using a [shitty JSVM](https://geth.ethereum.org/docs/interface/javascript-console#Caveats)
         * Used sim

3. Check result
    a. how to check?
        i. use the hash to read the transaction?

4. Generate trace
    a. how to guarantee the same trace every time?
        * Copy snapshot?
          * Also need to copy the user directory
        
        