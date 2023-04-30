#!/bin/xonsh

import os

ETH_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')

SEPOLIA_PATH = os.path.join(ETH_PATH, 'workdir', 'sepolia')

if 'ARG1' in ${...}:
	if $ARG1 == 'trace':
		geth --sepolia --datadir @(SEPOLIA_PATH).mp &
		sleep 1m
		killall -INT geth
	elif $ARG1 == 'ltrace':
		rm -rf @(SEPOLIA_PATH).snapshot
		cp -r @(SEPOLIA_PATH) @(SEPOLIA_PATH).snapshot
		geth --sepolia --datadir @(SEPOLIA_PATH) --tracing 2> traces/stacktraces &
		sleep 1m
		killall -INT geth
		grep '[trace]' @(SEPOLIA_PATH)/geth/chaindata/LOG > traces/spl-trace
	elif $ARG1 == 'inject':
		geth --sepolia --datadir @(SEPOLIA_PATH) @($ARGS[2:])
else:
	geth --sepolia --datadir @(SEPOLIA_PATH)
