#!/bin/bash
for i in out1 err2 err3 out4 out5 out6 err7 out8
do
    sleep 1s
    if echo "$i" | grep "out" > /dev/null
    then
        echo "$i"
    else
        >&2 echo "$i"
    fi
done
