#!/bin/bash

# This script just initializes a cluster of ZooKeeper nodes with just one key value pair
# Kill all ZooKeeper instances
pkill -f 'java.*zoo*'
ZK_HOME=$HOME'/zookeeper-3.4.12/'
CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if ! (ip a | grep 127.0.0.2 > /dev/null &2> /dev/null) ; then
	echo Setting up loopback addresses \(need sudo\)
	sudo ip addr add 127.0.0.2/8 dev lo label lo:1
	sudo ip addr add 127.0.0.3/8 dev lo label lo:2
	sudo ip addr add 127.0.0.4/8 dev lo label lo:3
fi

#Delete all the CORDS trace files
#Delete ZooKeeper workload directories
rm -rf cordslog*
rm -rf trace*
rm -rf workload_dir*

# Create workload directories for 3 nodes
# Create the required files for ZooKeeper
mkdir workload_dir0
mkdir workload_dir1
mkdir workload_dir2

touch workload_dir0/myid
touch workload_dir1/myid
touch workload_dir2/myid

echo '1' > workload_dir0/myid
echo '2' > workload_dir1/myid
echo '3' > workload_dir2/myid

#Start the 3 nodes in the Zookeeper Cluster.
$ZK_HOME/bin/zkServer.sh start $CURR_DIR/zoo0.cfg 
$ZK_HOME/bin/zkServer.sh start $CURR_DIR/zoo1.cfg 
$ZK_HOME/bin/zkServer.sh start $CURR_DIR/zoo2.cfg 

sleep 2

# Insert key value pairs to ZooKeeper
value=$(printf 'a%.s' {1..8192})
echo 'create /zk_test '$value > script
$ZK_HOME"/bin/zkCli.sh" -server 127.0.0.2:2182 < script


# Kill all ZooKeeper instances
rm -rf script
if pgrep zoo ; then
	echo 'Zookeeper is running, the processes will be killed'
else
	echo 'Zookeeper is not running'
fi
pkill -f 'java.*zoo*'
rm -rf zookeeper.out
