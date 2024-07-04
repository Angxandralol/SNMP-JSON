#!/bin/bash

community=$1
ip=$2
req=$3
part=$4

/usr/sfw/bin/snmpwalk -v 2c -c $community $ip $req >> "output_$part.txt"