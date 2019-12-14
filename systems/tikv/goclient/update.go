package main

import (
    "fmt"
    "strings"

    "github.com/pingcap/tidb/config"
    "github.com/pingcap/tidb/store/tikv"
)

func main() {
	cli, err := tikv.NewRawKVClient([]string{"127.0.0.1:2379", "127.0.0.1:2380", "127.0.0.1:2381"}, config.Security{})
    if err != nil {
        panic(err)
    }
    defer cli.Close()

    key := []byte("b")
    val := []byte(strings.Repeat("b", 8192))

    // put key into tikv
    err = cli.Put(key, val)
    if err != nil {
        panic(err)
    }
    fmt.Printf("Successfully put to tikv\n")
}
