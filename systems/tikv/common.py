import sys
import subprocess
import os
from pathlib import Path

# Warning: if the folder hierarchy changes, make sure to modify these variables to reflect the changes
CURR_DIR = os.path.dirname(os.path.realpath(__file__))
CORDS_HOME = Path(__file__).parent.parent.parent.as_posix()

def logger_log(log_dir, str):
	if log_dir:
		assert os.path.isdir(log_dir) and os.path.exists(log_dir), "Logging directory {} does not exist".format(log_dir)
		client_log_file = os.path.join(log_dir, 'log-client')
		with open(client_log_file, 'a') as f:
			f.write(str)
	else:
		print(str.replace('\n', ';'))


def check_isup(callback, retries=3, interval=5):
    """Check and return the health info and leader info"""
    import requests, json

    ret = ''
    leader = None
    res = requests.get('http://localhost:2379/pd/api/v1/stores')
    while retries > 0:
        if res.status_code == 200:
            s = json.loads(res.text)
            # sort the TiKVs by their addresses
            stores = sorted(s['stores'], key=lambda x: x["store"]["address"])
            for i, store in enumerate(stores):
                # Distinguish leader from its unique fields
                if "leader_size" in store["status"]:
                    callback('(leader) ')
                    leader = i
                callback('tikv_{}: '.format(i))
                # Print if the store is up
                callback(store["store"]["state_name"])
                callback('\n')
            break
        else:
            if retries > 0:
                time.sleep(interval)
                retries -= 1
            else:
                # cannot connect to PD
                callback("Cannot access PD API, is it running?")


def invoke(cmd, print_msg=False):
    """Invoke the command, if `print_msg` is true, print the message, else save the outputs to variables"""
    if print_msg is False:
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        outs, errs = p.communicate()
        outs = outs.decode()
        errs = errs.decode()
        ret = p.returncode
        return ret, outs, errs
    else:
        p = subprocess.Popen(cmd, shell=True)
        p.wait()
        return p.returncode, None, None


def checked_invoke(cmd):
    """Check the return code of the method. if the return code is nonzero, print an error and exit"""
    ret, outs, errs = invoke(cmd, print_msg=False)
    # Throw an assertion error if the return code is nonzero
    assert ret == 0, outs + errs + "[ERROR] Invocation {} failed, exiting".format(cmd)
