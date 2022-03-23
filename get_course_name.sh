#!/usr/bin/env bash
echo 

if [ -z ${1} ];
then
    echo "drop an imscc file into this window to get the course name and teacher"
    SKIP=1
else
    SKIP=0
fi

NODES=()
TARGET_FILE="imsmanifest.xml"

if [ $SKIP -lt 1 ]; 
then
    tar -zxvf "$1" -C /tmp $TARGET_FILE
    while IFS= read -r line; do
        NODES+=( "$line" )
    done < <( xpath -q -e "//lomm:string/text()" /tmp/$TARGET_FILE )

    for j in  "${NODES[@]}"
        do
            echo $j
        done
fi