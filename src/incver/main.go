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

type StreamCommandOptions struct {
    outFormat string
    errFormat string
}

func streamCommand(options StreamCommandOptions, name string, arg ...string) chan string {
    resultChan := make(chan string, 1)
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
                        resultChan <- line
                    } else {
                        exitOut = true
                    }
                case line, ok := <-errChan:
                    if ok {
                        resultChan <- line
                    } else {
                        exitErr = true
                    }
            }
        }
        cmd.Wait()
        close(resultChan)
    } ()
    return resultChan
}

func main() {
    channel := streamCommand(StreamCommandOptions{}, "sh", "-c", "./test.sh")
    for {
        line, ok := <-channel
        if ok {
            fmt.Printf(line)
        } else {
            break
        }
    }
}

