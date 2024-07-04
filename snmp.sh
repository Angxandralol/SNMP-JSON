#!/bin/bash

COMMAND="snmpwalk"

community=$1
ip=$2
req=$3
part=$4

$COMMAND -v 2c -c $community $ip $req >> "output_$part.txt"