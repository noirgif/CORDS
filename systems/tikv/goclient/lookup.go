package main

import (
    "fmt"
    "strings"
    "bytes"

    "github.com/pingcap/tidb/config"
    "github.com/pingcap/tidb/store/tikv"
)

func main() {
	cli, err := tikv.NewRawKVClient([]string{"127.0.0.1:2379", "127.0.0.1:2380", "127.0.0.1:2381"}, config.Security{})
    if err != nil {
        panic(err)
    }
    defer cli.Close()

    key := []byte("a")
    val_intended := []byte(strings.Repeat("a", 8192))
    var val []byte

    // put key into tikv
    // err = cli.Put(key, val)
    // if err != nil {
    //     panic(err)
    // }
    // fmt.Printf("Successfully put to tikv\n", key, val)

    // get key from tikv
    val, err = cli.Get(key)
    if err != nil {
        panic(err)
    }

    if bytes.Compare(val_intended, val) == 0 {
    	fmt.Printf("Proper")
	} else {
		fmt.Printf("Improper")
	}

    // delete key from tikv
    // err = cli.Delete(key)
    //if err != nil {
    //    panic(err)
    // }
    //fmt.Printf("key: %s deleted\n", key)
}
