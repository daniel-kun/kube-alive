package main

import (
    "os/exec";
    "bufio";
    "fmt";
    "time";
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

type StreamCommandOptions struct {
    outFormat string
    errFormat string
}

type ReceiverNotification struct {
    finished bool
    payload string
}

type RegisterNotification struct {
    registerChan chan ReceiverNotification
    unregisterChan chan ReceiverNotification
}

func removeFromSlice(input []chan ReceiverNotification, chanToBeRemoved chan ReceiverNotification) []chan ReceiverNotification {
    var result []chan ReceiverNotification
    for _, c := range input {
        if c != chanToBeRemoved {
            result = append(result, c)
        }
    }
    return result
}

func streamCommand(options StreamCommandOptions, name string, arg ...string) chan RegisterNotification {
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
        fmt.Printf("Waiting for cmd\n")
        cmd.Wait()
        fmt.Printf("cmd finished\n")
    } ()
    return registerChan
}

func readOutput(prefix string, registerChan chan RegisterNotification) {
    receiveChan := make(chan ReceiverNotification, 1)
    registerChan <- RegisterNotification{receiveChan,nil}
    for {
        notif, ok := <-receiveChan
        if ok {
            if notif.finished {
                fmt.Printf("Closing %s\n", prefix)
                close(receiveChan)
                break
            } else {
                fmt.Printf("%s: %s", prefix, notif.payload)
            }
        } else {
            break
        }
    }
    fmt.Printf("Done with %s\n", prefix)
}

func main() {
    registerChan := streamCommand(StreamCommandOptions{}, "sh", "-c", "./test.sh")
    finishChan := make(chan ReceiverNotification, 1)
    registerChan <- RegisterNotification {finishChan, nil}
    go readOutput("A", registerChan)
    go readOutput("B", registerChan)
    go readOutput("C", registerChan)
    duration, _ := time.ParseDuration("2s")
    time.Sleep(duration)
    for {
        notif, ok := <-finishChan
        if notif.finished || !ok {
            break
        }
    }

}

