#!/bin/bash

geth --datadir workdir/user init config/geth-genesis.json

# for now it is the user that submit the transaction
cp config/keys/user-{1,2} workdir/user/keystore