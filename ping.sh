#!/bin/bash

ip=$1
part=$2

if [ -f "ping_$part.txt" ]; then
    rm "ping_$part.txt"
fi

ping $ip 1 >> "ping_$part.txt"



