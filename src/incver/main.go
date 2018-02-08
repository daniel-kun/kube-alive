package main

import (
    "os/exec";
    "bufio";
    "fmt";
    "github.com/gorilla/websocket";
    "net/http";
    "sync";
    "os";
    )

func readInBackground (reader *bufio.Reader, channel chan string) {
    for {
        line, err := reader.ReadString('\n')
        if err != nil {
            break
        }
        channel <- line
    }
    close(channel)
}

type ReceiverNotification struct {
    finished bool
    payload string
}

type RegisterNotification struct {
    registerChan chan ReceiverNotification
}

func streamCommand(name string, arg ...string) chan RegisterNotification {
    registerChan := make(chan RegisterNotification, 1)
    var receiverChans []chan ReceiverNotification;
    go func() {
        cmd := exec.Command(name, arg...)
        cmdOutPipe, err := cmd.StdoutPipe()
        if err != nil {
            return
        }
        cmdErrPipe, err := cmd.StderrPipe()
        if err != nil {
            return
        }
        outReader := bufio.NewReader(cmdOutPipe)
        errReader := bufio.NewReader(cmdErrPipe)
        outChan := make(chan string, 1)
        errChan := make(chan string, 1)
        cmd.Start()
        go readInBackground(outReader, outChan)
        go readInBackground(errReader, errChan)
        for exitOut, exitErr := false, false; !(exitOut && exitErr); {
            select {
                case line, ok := <-outChan:
                    if ok {
                        for _, receiverChan := range receiverChans {
                            notif := ReceiverNotification{false, line}
                            receiverChan <- notif
                        }
                    } else {
                        exitOut = true
                    }
                case line, ok := <-errChan:
                    if ok {
                        for _, receiverChan := range receiverChans {
                            notif := ReceiverNotification{false, line}
                            receiverChan <- notif
                        }
                    } else {
                        exitErr = true
                    }
                case registerNotif, _ := <-registerChan:
                    if registerNotif.registerChan != nil {
                        receiverChans = append(receiverChans, registerNotif.registerChan)
                    }
            }
        }
        for _, receiverChan := range receiverChans {
            receiverChan <- ReceiverNotification{true, ""}
        }
        receiverChans = []chan ReceiverNotification{}
        close(registerChan)
        cmd.Wait()
        fmt.Printf("cmd finished\n")
    } ()
    return registerChan
}

func receiveOutput(prefix string, registerChan chan RegisterNotification) {
    receiveChan := make(chan ReceiverNotification, 1)
    registerChan <- RegisterNotification{receiveChan}
    for {
        notif, ok := <-receiveChan
        if ok {
            if notif.finished {
                close(receiveChan)
                break
            } else {
                fmt.Printf("%s: %s", prefix, notif.payload)
            }
        } else {
            break
        }
    }
    fmt.Printf("%s closed\n", prefix)
}

func main() {
    var upgrader = websocket.Upgrader{
        ReadBufferSize:  1024,
        WriteBufferSize: 1024,
        CheckOrigin: func(r *http.Request) bool {
            return true
        },
    }
    var registerChan chan RegisterNotification
    registerChan = nil
    var registerChanLock sync.Mutex
    http.HandleFunc("/version", func(w http.ResponseWriter, r *http.Request) {
        w.Write([]byte(os.Getenv("INCVER_VERSION")))
    })
	http.HandleFunc("/start", func(w http.ResponseWriter, r *http.Request) {
        var response string
        if registerChan != nil {
            response = "Command already running";
            w.WriteHeader(http.StatusForbidden)
        } else {
            response = "Starting command"
            registerChanLock.Lock()
            registerChan = streamCommand("sh", "-c", "./test.sh")
            cleanupChan := make(chan ReceiverNotification, 1)
            registerChan <- RegisterNotification{registerChan: cleanupChan}
            registerChanLock.Unlock()
            go func () {
                for {
                    finished := false
                    select {
                        case notif, ok := <-cleanupChan:
                            if notif.finished || !ok {
                                finished = true
                                registerChanLock.Lock()
                                registerChan = nil
                                registerChanLock.Unlock()
                            }
                    }
                    if finished {
                        break
                    }
                }
            } ()
        }
        fmt.Println(response)
        w.Write([]byte(response))
    })
	http.HandleFunc("/status", func(w http.ResponseWriter, r *http.Request) {
        registerChanLock.Lock()
        hasRegisterChan := registerChan != nil
        registerChanLock.Unlock()

        if !hasRegisterChan {
            fmt.Print("Status requested, but no command running\n")
        } else {
            fmt.Print("Handling status request\n")
            ws, err := upgrader.Upgrade(w, r, nil)
            if err != nil {
                fmt.Print(err)
            } else {
                receiveChan := make(chan ReceiverNotification, 1)
                registerChanLock.Lock()
                registerChan <- RegisterNotification{registerChan: receiveChan}
                registerChanLock.Unlock()
                for {
                    finished := false
                    select {
                        case notif, ok := <-receiveChan:
                            if !ok || notif.finished {
                                writer, _ := ws.NextWriter(websocket.TextMessage)
                                writer.Write([]byte("finished"))
                                writer.Close()
                                finished = true;
                                break;
                            }
                            writer, _ := ws.NextWriter(websocket.TextMessage)
                            writer.Write([]byte(notif.payload))
                            writer.Close()
                    }
                    if finished {
                        break
                    }
                }
            }
        }
    })
    http.Handle("/", http.FileServer(http.Dir("./static")))
	fmt.Printf("'incver' server starting, listening to 8080 on all interfaces.\n")
	http.ListenAndServe(":8080", nil)
}

