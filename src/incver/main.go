package main

import (
    "os/exec";
    "bufio";
    "fmt";
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
    unregisterChan chan ReceiverNotification
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
    registerChan <- RegisterNotification{receiveChan,nil}
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

func wrapWithFinishChannel(fnc func(string, chan RegisterNotification), prefix string, registerChan chan RegisterNotification) chan bool {
    result := make(chan bool, 1)
    go func() {
        fnc(prefix, registerChan)
        result <- true
    } ()
    return result;
}

func main() {
    registerChan := streamCommand("sh", "-c", "./test.sh")
    finishChanA := wrapWithFinishChannel(receiveOutput, "A", registerChan)
    finishChanB := wrapWithFinishChannel(receiveOutput, "B", registerChan)
    finishChanC := wrapWithFinishChannel(receiveOutput, "C", registerChan)

    finishedA := false
    finishedB := false
    finishedC := false
    for !(finishedA && finishedB && finishedC) {
        select {
            case finished, ok := <-finishChanA:
                if finished || !ok {
                    finishedA = true
                }
            case finished, ok := <-finishChanB:
                if finished || !ok {
                    finishedB = true
                }
            case finished, ok := <-finishChanC:
                if finished || !ok {
                    finishedC = true
                }
        }
    }
    fmt.Print("Bye bye!\n")
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

