#!/bin/bash

COMMAND="ping"

ip=$1
part=$2

if [ -f "ping_$part.txt" ]; then
    rm "ping_$part.txt"
fi

$COMMAND $ip 1 >> "ping_$part.txt"



