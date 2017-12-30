package main

import "fmt"
import "bufio"
import "os/exec"
import "log"
import "strings"
import "net/http"

/**

getmac starts an HTTP server on 8080 that returns nothing but this contain's IP address (the last one outputted by "ip a").

For demo purposes only.

**/

func getIP() string {
  var result string
	cmd := exec.Command("ip", "a")
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		log.Fatal(err)
	}
	if err := cmd.Start(); err != nil {
		log.Fatal(err)
	}
	scanner := bufio.NewScanner(stdout)
  result = ""
	for scanner.Scan() {
		fullLine := scanner.Text()
		line := strings.TrimLeft(fullLine, " \t\r\n")
    keyword := "inet "
		if strings.Index(line, keyword) == 0 {
      inetTruncated := line[len(keyword):len(line)]
      endOfIp := strings.IndexAny(inetTruncated, "\t /")
      if endOfIp > 0 {
        result = inetTruncated[0:endOfIp]
      }
		}
	}
	return result
}

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, getIP())
	})
	fmt.Printf("'getmac' server starting, listening to 8080 on all interfaces.\n")
	http.ListenAndServe(":8080", nil)
}

/*
EXAMPLE OUTPUT of "ip a":

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
39: eth0@if40: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1376 qdisc noqueue state UP group default 
    link/ether 2e:9a:02:91:03:49 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.32.0.13/12 scope global eth0
       valid_lft forever preferred_lft forever

*/
