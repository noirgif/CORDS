// Loop until the block is found
let checkBlock = function () {
    // Check if the block is found
    if (eth.getBlock("latest").number > 1) {
        // If the block is found, stop the interval
        console.log("Block found" + eth.getBlock("latest").number);
        return;
    } else {
        // If the block is not found, check again in 1 second
        setTimeout(checkBlock, 1000);
    }
}

checkBlock();