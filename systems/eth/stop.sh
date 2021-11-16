#!/bin/bash

killall -INT geth 2>/dev/null

while sleep 1 ; do
        if ! pgrep geth &>/dev/null ; then
                break;
        fi
done

echo "Stopped geth"