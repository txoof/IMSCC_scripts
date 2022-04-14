#!/usr/bin/env bash

MY_ARGS=("$@")


if [ ${#MY_ARGS[@]} -lt 1 ];
then
    echo "drop imscc file(s) into this window to get the course name and teacher"
    exit
fi

TARGET_FILE="imsmanifest.xml"

for i in "${MY_ARGS[@]}"
do
    NODES=()
    echo "-------------------------"

    tar -zxvf "$i" -C /tmp $TARGET_FILE 
    while IFS= read -r line; do
        NODES+=( "$line" )
    done < <( xpath -q -e "//lomm:string/text()" /tmp/$TARGET_FILE )
    printf "File: $1\n"
    for j in  "${NODES[@]}"
        do
            echo $j
        done
    echo ""
done