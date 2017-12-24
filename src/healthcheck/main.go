package main

import "fmt"
import "os"
import "net/http"

/**

healthcheck serves a simple response ("Hi, I'm alive an healthy!") and can be made
unhealthy (via POST /infect) or crashed (POST /kill). For experimental purposes, it can me
made healthy again (via POST /cure).
When it is unhealthy, the response is changed to "Ugh, I'm not feeling so well...".

For demo purposes only.

**/

func main() {
  healthy := true
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
    if healthy {
      fmt.Fprintf(w, "Hi, I'm alive an healthy!")
    } else {
      fmt.Fprintf(w, "Ugh, I'm not feeling so well...")
    }
	})
  http.HandleFunc("/infect", func(w http.ResponseWriter, r *http.Request) {
    if r.Method == "POST" {
      healthy = false
      fmt.Printf("Ugh, I've been infected. Now unhealthy.\n")
    }
  })
  http.HandleFunc("/cure", func(w http.ResponseWriter, r *http.Request) {
    if r.Method == "POST" {
      healthy = true
      fmt.Printf("Yay, I've been cured! Now healthy.\n")
    }
  })
  http.HandleFunc("/kill", func(w http.ResponseWriter, r *http.Request) {
    if r.Method == "POST" {
      fmt.Printf("R.I.P.\n")
      os.Exit(1)
    }
  })
	fmt.Printf("'healthcheck' server starting, listening to 8080 on all interfaces.\n")
	http.ListenAndServe(":8080", nil)
}

