#!/bin/bash

FILEPATH_COMMUNITIES="elements.csv"

function deleteFile {
    file=$1  
    if [ -f $file ]; then
        rm $file
    fi
}

function validatorPing {
    ip=$1
    part=$2

    bash ping.sh $ip $part
    if [ -f "ping_$part.txt" ]; then
        output=$(cat "ping_$part.txt" | grep "is alive")
        if [ -n "$output" ]; then
            echo 1
        else
            echo 0
        fi
    fi
}

function generateJson {
    ip=$1
    community=$2
    part=$3
    json=""
    IFS=;
    if [ -f "output_$part.txt" ]; then
        while IFS= read -r line; do
            if [[ "$line" == *"::ifIndex"* ]]; then 
                index=$(echo "$line" | cut -d ':' -f 4)
                index=$(echo "$index" | cut -d ' ' -f 2)

                valueLine=$(cat "output_$part.txt" | grep "ifName.${index} =")
                if [ ${#valueLine} != "0" ]; then
                    name=$(echo "$valueLine" | cut -d ':' -f 4)
                    name=$(echo "$name" | cut -d ' ' -f 2)
                    name=$(echo "$name" | sed 's/\"//g')
                fi

                valueLine=$(cat "output_$part.txt" | grep "ifDescr.${index} =")
                if [ ${#valueLine} != "0" ]; then
                    descr=$(echo "$valueLine" | cut -d ':' -f 4)
                    descr=$(echo "$descr" | cut -d ' ' -f 2)
                    descr=$(echo "$descr" | sed 's/\"//g')
                fi

                valueLine=$(cat "output_$part.txt" | grep "ifAlias.${index} =")
                if [ ${#valueLine} != "0" ]; then
                    alias=$(echo "$valueLine" | cut -d ':' -f 4)
                    alias=$(echo "$alias" | cut -d ' ' -f 2)
                    alias=$(echo "$alias" | sed 's/\"//g')
                fi

                valueLine=$(cat "output_$part.txt" | grep "ifHighSpeed.${index} =")
                if [ ${#valueLine} != "0" ]; then
                    highSpeed=$(echo "$valueLine" | cut -d ':' -f 4)
                    highSpeed=$(echo "$highSpeed" | cut -d ' ' -f 2)
                    highSpeed=$(echo "$highSpeed" | sed 's/\"//g')
                fi

                valueLine=$(cat "output_$part.txt" | grep "ifOperStatus.${index} =")
                if [ ${#valueLine} != "0" ]; then
                    operStatus=$(echo "$valueLine" | cut -d ':' -f 4)
                    operStatus=$(echo "$operStatus" | cut -d ' ' -f 2)
                    operStatus=$(echo "$operStatus" | sed 's/\"//g')
                fi

                valueLine=$(cat "output_$part.txt" | grep "ifAdminStatus.${index} =")
                if [ ${#valueLine} != "0" ]; then
                    adminStatus=$(echo "$valueLine" | cut -d ':' -f 4)
                    adminStatus=$(echo "$adminStatus" | cut -d ' ' -f 2)
                    adminStatus=$(echo "$adminStatus" | sed 's/\"//g')
                fi

                newJson="{\"ip\": \"$ip\", \"community\": \"$community\", \"ifIndex\": \"$index\", \"ifName\": \"$name\", \"ifDescr\": \"$descr\", \"ifAlias\": \"$alias\", \"ifHighSpeed\": \"$highSpeed\", \"ifOperStatus\": \"$operStatus\", \"ifAdminStatus\": \"$adminStatus\"}"
                newJson+=","
                json+="$newJson"
            fi
        done < "output_$part.txt"
    fi
    echo $json >> "data_$part.json"
}

function getSNMPByInterface {
    consults=$1
    part=$2

    if [ -f $FILEPATH_COMMUNITIES ]; then
        deleteFile "data_$part.json"
        IFS=,
        data=($(cat $FILEPATH_COMMUNITIES))
        total=${#data[@]} 
        realTotal=$((${#data[@]} / 2))
        if [ $consults -le $realTotal ]; then
            index=$((($consults * 2) * ($part - 1)))
            consultTotal=$((($consults * 2) + $index - 1))
            flag=0
            for (( i = $index; i <= $consultTotal; i += 2)); do
                flag=$(( flag + 1 ))
                j=$(( i + 1 ))
                deleteFile "output_$part.txt"
                ip=(${data[i]})
                community=(${data[j]})
                if [ -n "$ip" -a -n "$community" ]; then
                    echo "Validating connection to server ... $flag/$consults"
                    server=$(validatorPing $ip $part)
                    if [ $server -eq 0 ]; then
                        echo "$ip no response ..."
                    elif [ $server -eq 1 ]; then
                        echo "Response received ..."
                        echo "Create SNMP request ... IP: $ip, Community: $community"
                        bash snmp.sh $community $ip "ifIndex" $part
                        bash snmp.sh $community $ip "ifName" $part
                        bash snmp.sh $community $ip "ifDescr" $part
                        bash snmp.sh $community $ip "ifAlias" $part
                        bash snmp.sh $community $ip "ifHighSpeed" $part
                        bash snmp.sh $community $ip "ifOperStatus" $part
                        bash snmp.sh $community $ip "ifAdminStatus" $part
                        generateJson $ip $community $part
                        echo "Responses received"
                    fi
                fi
                clear
            done

            if [ -f "data_$part.json" ]; then
                data_completed="{\"snmp\": ["
                json=$(cat "data_$part.json")
                if [ -n "$json" ]; then
                    json=${json::$((${#json}-1))}
                fi
                data_completed+=$json
                data_completed+="]}"

                echo "$data_completed" > "data_$part.json"
                
                deleteFile "output_$part.txt"
                deleteFile "ping_$part.txt"
            fi
        else
            echo "WARNING: Number of invalid requests."
        fi
    else    
        echo "WARNING: It is necessary to have a file containing the list of the objects to be consulted."
    fi
}

consults=$1
part=$2
echo "Process started ..."
getSNMPByInterface $consults $part
echo "Process completed."