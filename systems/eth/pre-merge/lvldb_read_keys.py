#!/usr/bin/env python3
import leveldb
import sys
import rlp

if len(sys.argv) < 2:
    print("Usage: read_keys.py <db_path>")
    sys.exit(1)
elif len(sys.argv) == 2:
    db = leveldb.LevelDB(sys.argv[1])
    for k in db.RangeIter(include_value = False):
        v = db.Get(k)
        try:
            print('K', k, 'V', rlp.decode(v))
        except rlp.exceptions.DecodingError:
            print('K', k, 'V', v)
else:
    # db1 = leveldb.LevelDB(sys.argv[1])
    # db2 = leveldb.LevelDB(sys.argv[2])

    # for k, v in db1.RangeIter(include_value = True):
    #     if db2.Get(k) != v:
    #         print('K', k, 'V1', v, 'V2', db2.Get(k))
    if sys.argv[2] == 'normal':
        db = leveldb.LevelDB(sys.argv[1])
    for k in db.RangeIter(include_value = False):
        v = db.Get(k)
        print('K', k, 'V', v)