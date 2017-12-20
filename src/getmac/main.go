package main

import "fmt"
import "bufio"
import "os/exec"
import "log"
import "strings"
import "net/http"

func getMAC() string {
	cmd := exec.Command("ifconfig", "eth0")
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
		if len(line) > 24 && strings.Index(line, "ether ") == 0 {
			return line[len("ether "):len("ether ")+18]
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
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.178.80  netmask 255.255.255.0  broadcast 192.168.178.255
        inet6 2001:16b8:482:2000:63ce:b7fb:2d82:d8ae  prefixlen 64  scopeid 0x0<global>
        inet6 fe80::dd1d:5e8e:52ab:fdc8  prefixlen 64  scopeid 0x20<link>
ether b8:27:eb:90:92:aa  txqueuelen 1000  (Ethernet)
        RX packets 228749  bytes 244755521 (233.4 MiB)
        RX errors 0  dropped 1548  overruns 0  frame 0
        TX packets 77559  bytes 31008189 (29.5 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

*/

