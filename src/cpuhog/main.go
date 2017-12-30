package main

import "fmt"
import "time"
import "net/http"

/**

cpuhog starts an HTTP server on 8080 that occupies the CPU for 2 seconds
for every request it receives.

For demo purposes only.

**/

func occupyCPU () string {
  start := time.Now()
  second, _ := time.ParseDuration("1000ms")
  end := start.Add(second)
  i := 0
  for time.Now().Before(end) {
    i = i + 1
  }
  return fmt.Sprintf("%d", i)
}

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, occupyCPU())
	})
	fmt.Printf("'cpuhog' server starting, listening to 8080 on all interfaces.\n")
	http.ListenAndServe(":8080", nil)
}

