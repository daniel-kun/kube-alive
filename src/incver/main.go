package main

import (
    "os/exec";
    "bufio";
    "fmt";
    "github.com/gorilla/websocket";
    "net/http";
    "sync";
    "os";
    "strconv";
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
            fmt.Printf("Error 1: %s\n", err)
            return
        }
        cmdErrPipe, err := cmd.StderrPipe()
        if err != nil {
            fmt.Printf("Error 2: %s\n", err)
            return
        }
        outReader := bufio.NewReader(cmdOutPipe)
        errReader := bufio.NewReader(cmdErrPipe)
        outChan := make(chan string, 1)
        errChan := make(chan string, 1)
        errStart := cmd.Start()
        if errStart != nil {
            fmt.Printf("Error 3: %s", errStart)
        }
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
        errCmd := cmd.Wait()
        if errCmd != nil {
            fmt.Printf("Error 4: %s\n", errCmd)
        }
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

func getVersion() string {
    return os.Getenv("INCVER_VERSION")
}

func getVersionInt() int {
    result, err := strconv.Atoi(getVersion())
    if err == nil {
        return result
    } else {
        return 0
    }
}

func getNextVersion() int {
    if getVersionInt() >= 5 {
        // When reaching version 5, make a round-trip to 1 when an update is requested, because only
        // 5 container versions are available.
        return 1
    } else {
        return getVersionInt() + 1
    }
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
        w.Write([]byte(getVersion()))
    })
	http.HandleFunc("/start", func(w http.ResponseWriter, r *http.Request) {
        var response string
        if registerChan != nil {
            response = "Command already running";
            w.WriteHeader(http.StatusForbidden)
        } else {
            response = "Starting command"
            registerChanLock.Lock()
            registerChan = streamCommand(
                    "./deploy.sh",
                    fmt.Sprintf("%d", getNextVersion()))
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
                            } else {
                                fmt.Printf(">> %s", notif.payload)
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
	fmt.Printf("'incver' server v%s starting, listening to 8080 on all interfaces.\n", getVersion())
	http.ListenAndServe(":8080", nil)
}

