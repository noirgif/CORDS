#!/usr/bin/env python3

import logging
import subprocess
import os
# for indexing paths
from pathlib import Path
import sys
import time
from common import CURR_DIR, CORDS_HOME, logger_log, check_isup, invoke, checked_invoke


def main():
    logging.basicConfig()
    os.chdir(CURR_DIR)

    # Set up the directories of servers, and logs
    server_dirs = []
    log_dir = None
    if len(sys.argv) >= 4:
        for i in range(2, 5):
            server_dirs.append(sys.argv[i]) 
        work_dir = Path(server_dirs[0]).parent.parent

        #if logdir specified
        if len(sys.argv) == 6:
            log_dir = sys.argv[-1]
    else:
        print(sys.argv[0], 'x', 'server directory [1..3]', '{log directory}')
        exit(0)


    # Initializing
    DOCKER_COMPOSE_DIR = Path(CORDS_HOME).joinpath('systems/tikv/tidb-docker-compose')
    command = "./tikv_up.sh {0} {1} {2}".format(*(str(Path(server_dir).relative_to(DOCKER_COMPOSE_DIR)) for server_dir in server_dirs))
    # print(command, file=sys.stderr)
    checked_invoke(command)
    # No need to wait here, the wait is done at up script
    
    # Check health state before starting
    if log_dir:
        logger_log(log_dir, 'Before workload\n')
        check_isup(lambda x: logger_log(log_dir, x))
        logger_log(log_dir, '\n')
        logger_log(log_dir, '-' * 30)
        logger_log(log_dir, '\n')
    
    # Server logs recides under the working directory as the data
    # working directory for all nodes <- work_dir
    # - node working directory
    # - - data <- server_dirs
    # - - logs <- server_logs_hosts
    server_logs_hosts = []
    for i in range(0, len(server_dirs)):
	    server_logs_hosts.append(str(Path(server_dirs[i]).parent.joinpath('logs')))

    # no update when reading
    # checked_invoke("cd goclient && go run delete.go")
    ret, outs, errs = invoke("cd goclient && go run lookup.go")

    logger_log(log_dir, outs)
    logger_log(log_dir, errs)

    # Check health state after starting
    if log_dir:
        logger_log(log_dir, '-' * 30)
        logger_log(log_dir, '\nAfter workload\n')
        check_isup(lambda x: logger_log(log_dir, x))
        logger_log(log_dir, '\n')
        logger_log(log_dir, '-' * 30)
    
    # Stopping the containers
    print('Stopping containers...')
    checked_invoke("./tikv_down.sh")

    # if log_dir specified, move server log to the system log
    if log_dir is not None:
        for i in range(0, len(server_dirs)):
            os.system('mv ' + server_logs_hosts[i]  + ' '  + os.path.join(log_dir, 'log-'+str(i)))



if __name__ == "__main__":
    main()
