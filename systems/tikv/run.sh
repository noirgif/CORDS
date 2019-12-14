#!/bin/bash

./tikv_init.sh
cd ../..
./trace.py --trace_files ./systems/tikv/readtrace/trace{0,1,2} --data_dirs ./systems/tikv/tidb-docker-compose/workdir/tikv0/data ./systems/tikv/tidb-docker-compose/workdir/tikv1/data ./systems/tikv/tidb-docker-compose/workdir/tikv2/data --workload_command ./systems/tikv/tikv_workload_read.py
./cords.py --trace_files ./systems/tikv/readtrace/trace{0..2} --data_dirs ./systems/tikv/tidb-docker-compose/workdir/tikv{0,1,2}/data --workload_command ./systems/tikv/tikv_workload_read.py --cords_results_base_dir $(realpath .)/systems/tikv/results-read --checker_command ./systems/tikv/move_pd.sh

cd systems/tikv
./tikv_init.sh
cd ../..
./trace.py --trace_files ./systems/tikv/writetrace/trace{0,1,2} --data_dirs ./systems/tikv/tidb-docker-compose/workdir/tikv0/data ./systems/tikv/tidb-docker-compose/workdir/tikv1/data ./systems/tikv/tidb-docker-compose/workdir/tikv2/data --workload_command ./systems/tikv/tikv_workload_update.py
./cords.py --trace_files ./systems/tikv/writetrace/trace{0..2} --data_dirs ./systems/tikv/tidb-docker-compose/workdir/tikv{0,1,2}/data --workload_command ./systems/tikv/tikv_workload_update.py --cords_results_base_dir $(realpath .)/systems/tikv/results-update --checker_command ./systems/tikv/move_pd.sh
