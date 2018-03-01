package main

import "fmt"
import "net/http"
import "io/ioutil"
import "github.com/gorilla/mux"



func main() {
    router := mux.NewRouter().StrictSlash(true)
    router.HandleFunc("/retrieve", func(w http.ResponseWriter, r *http.Request) {
        text, err := ioutil.ReadFile("text")
        if err != nil {
            fmt.Fprintf(w, "")
        } else {
            fmt.Fprintf(w, string(text))
        }
	})
	router.HandleFunc("/store/{text}", func(w http.ResponseWriter, r *http.Request) {
        vars := mux.Vars(r)
        text := vars["text"]
        ioutil.WriteFile("text", []byte(text), 0600)
	})
	fmt.Printf("'phoenix' server starting, listening to 8080 on all interfaces.\n")
	http.ListenAndServe(":8080", router)
}

