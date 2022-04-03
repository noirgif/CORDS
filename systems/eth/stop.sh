#!/bin/bash

if [[ $1 == "kill" ]] ; then
        killall -9 geth 2>/dev/null
else
        killall -INT geth 2>/dev/null
fi

while sleep 1 ; do
        if ! pgrep geth &>/dev/null ; then
                break;
        fi
done

echo "Stopped geth"