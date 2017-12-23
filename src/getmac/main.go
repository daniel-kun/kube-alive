package main

import "fmt"
import "bufio"
import "os/exec"
import "log"
import "strings"
import "net/http"

func getMAC() string {
	cmd := exec.Command("ip", "a")
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		log.Fatal(err)
	}
	if err := cmd.Start(); err != nil {
		log.Fatal(err)
	}
	scanner := bufio.NewScanner(stdout)
	for scanner.Scan() {
		fullLine := scanner.Text()
		line := strings.TrimLeft(fullLine, " \t\r\n")
    keyword := "link/ether "
		if len(line) > 24 && strings.Index(line, keyword) == 0 {
			return line[len(keyword):len(keyword)+18]
		}
	}
	return ""
}

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, getMAC())
	})
	fmt.Printf("'getmac' server starting, listening to 8080 on all interfaces.\n")
	http.ListenAndServe(":8080", nil)
}

/*
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether b8:27:eb:90:92:aa brd ff:ff:ff:ff:ff:ff
    inet 192.168.178.80/24 brd 192.168.178.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 2001:16b8:43e:0:7e9c:5bc0:b7de:d393/64 scope global mngtmpaddr noprefixroute dynamic 
       valid_lft 6686sec preferred_lft 3086sec
    inet6 fe80::dd1d:5e8e:52ab:fdc8/64 scope link 
       valid_lft forever preferred_lft forever
3: wlan0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc pfifo_fast state DOWN group default qlen 1000
    link/ether b8:27:eb:c5:c7:ff brd ff:ff:ff:ff:ff:ff
4: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:7c:11:71:31 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 scope global docker0
       valid_lft forever preferred_lft forever
    inet 169.254.204.56/16 brd 169.254.255.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::cb0c:3519:6183:10bf/64 scope link 
       valid_lft forever preferred_lft forever
5: datapath: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1376 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether 0e:23:57:76:e0:83 brd ff:ff:ff:ff:ff:ff
    inet 169.254.31.12/16 brd 169.254.255.255 scope global datapath
       valid_lft forever preferred_lft forever
    inet6 fe80::3152:c409:39ec:c879/64 scope link 
       valid_lft forever preferred_lft forever
7: weave: <NO-CARRIER,BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1376 qdisc noqueue state DORMANT group default qlen 1000
    link/ether ae:80:91:75:52:db brd ff:ff:ff:ff:ff:ff
    inet 10.40.0.0/12 scope global weave
       valid_lft forever preferred_lft forever
8: dummy0: <BROADCAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether aa:47:89:f5:b7:ed brd ff:ff:ff:ff:ff:ff
    inet6 fe80::1cf0:d0a0:4f54:4e11/64 scope link 
       valid_lft forever preferred_lft forever
10: vethwe-datapath@vethwe-bridge: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1376 qdisc noqueue master datapath state UP group default 
    link/ether 8a:7b:94:48:25:65 brd ff:ff:ff:ff:ff:ff
    inet 169.254.203.239/16 brd 169.254.255.255 scope global vethwe-datapath
       valid_lft forever preferred_lft forever
    inet6 fe80::887b:94ff:fe48:2565/64 scope link 
       valid_lft forever preferred_lft forever
11: vethwe-bridge@vethwe-datapath: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1376 qdisc noqueue master weave state UP group default 
    link/ether a2:e4:ec:9b:38:63 brd ff:ff:ff:ff:ff:ff
    inet 169.254.99.6/16 brd 169.254.255.255 scope global vethwe-bridge
       valid_lft forever preferred_lft forever
    inet6 fe80::a0e4:ecff:fe9b:3863/64 scope link 
       valid_lft forever preferred_lft forever
24: veth613b5b7@if23: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP group default 
    link/ether 9a:95:3a:76:4f:e8 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 169.254.21.128/16 brd 169.254.255.255 scope global veth613b5b7
       valid_lft forever preferred_lft forever
    inet6 fe80::9895:3aff:fe76:4fe8/64 scope link 
       valid_lft forever preferred_lft forever
25: vxlan-6784: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 65485 qdisc noqueue master datapath state UNKNOWN group default qlen 1000
    link/ether b6:19:df:74:b5:dd brd ff:ff:ff:ff:ff:ff
    inet6 fe80::b419:dfff:fe74:b5dd/64 scope link 
       valid_lft forever preferred_lft forever
*/

