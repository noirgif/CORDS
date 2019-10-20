0. Modify the configuration file in the directory(the cfg files). Only modify the dataDir in *.cfg. Also modify the path to zookeeper(it's zookeeper-3.4.12/ for now).

1. Run zk_init.sh . If your computer has no 127.0.0.{2..4} set up as loopback addresses, it will use sudo privilege to set it up.
If finally it says the zookeeper process is running, then everything is doing fine.

2. Go to the root directory of the repo, run 
```
trace.py --trace_files ./systems/zk/trace0 ./systems/zk/trace1 ./systems/zk/trace2 --data_dirs ./systems/zk/workload_dir0 ./systems/zk/workload_dir1/ ./systems/zk/workload_dir2/ --workload_command ./systems/zk/zk_workload_read.py --ignore_file ./systems/zk/ignore
```
There may be random failures, repeatedly run until all servers work properly.

3. Run
Stay in the project root. Run `make` first.

Run
```
cords.py --trace_files ./systems/zk/trace0 ./systems/zk/trace1 ./systems/zk/trace2 --data_dirs ./systems/zk/workload_dir0 ./systems/zk/workload_dir1/ ./systems/zk/workload_dir2/ --workload_command ./systems/zk/zk_workload_read.py --cords_results_base_dir $PWD/systems/zk/results
```
And the results should lie in the `results` folder.
