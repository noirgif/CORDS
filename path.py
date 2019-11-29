import os
import sys
from pathlib import Path

for arg in sys.argv[1:]:
    print("{}".format(str(Path(arg).relative_to('systems/tikv/tidb-docker-compose'))))
