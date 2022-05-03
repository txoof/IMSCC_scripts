#!/usr/bin/env bash

SOURCE=$1
# OUTPUT_PATH="/Volumes/GoogleDrive/Shared drives/PS12 IT Vertical Shared Drive/Team & Department Operations/PS12 IT Department Projects/2021 VLE Migration/PSL Migration to D2L/IMSCC Files"
DATE=$(date "+%Y%m%d.%H%M")
OUTPUT_PATH="$(dirname $SOURCE)"/imscc_renamed-$DATE/
TARGET_FILE="imsmanifest.xml"

echo $OUTPUT_PATH

slugify () {
    echo "$1" | iconv -c -t ascii//TRANSLIT | sed -E 's/[~^]+//g' | sed -E 's/[^a-zA-Z0-9]+/_/g' | sed -E 's/^-+|-+$//g' | tr A-Z a-z
}

abort() {
    echo $1
    echo "aborting execution"
    exit
}

mkdir "$OUTPUT_PATH" || abort "Output path '$OUTPUT_PATH' could not be created. Aborting."

[ ! -d "$OUTPUT_PATH" ] && abort "Output path cannot be found. Aborting."

[ -z $1 ] && abort "Provide a folder full of IMSCC files by dropping in this window or using: $0 /path/to/files"

[ ! -d $1 ] && abort "$1 does not appear to be a directory"


# glob everything in the source dir
shopt -s nullglob
arr=($SOURCE/*.imscc)

# array to capture any failed imscc files
FAILURES=( )


for ((i=0; i<${#arr[@]}; i++)); do
    tar -zxvf "${arr[$i]}" -C /tmp $TARGET_FILE
    if [ $? -ne 0 ];
    then
        # add failures to array here display at end
        echo "could not process ${arr[$i]}"
        FAILURES+=(${arr[$i]} )
        continue
    fi

    NODES=()
    while IFS= read -r line; do
        NODES+=( "$line" )
    done < <( xpath -q -e "//lomm:string/text()" /tmp/$TARGET_FILE )

    # teacher name
    T_NAME=$(slugify "${NODES[1]}")

    # course name
    C_NAME=$(slugify "${NODES[0]}")

    T_PATH=$OUTPUT_PATH/$T_NAME
    F_NAME="$T_NAME"."$C_NAME".imscc

    if [ ! -d "$T_PATH" ] 
    then
        mkdir "$T_PATH"
        if [ $? -ne 0 ]
        then
            echo "could not create directory: $T_PATH"
            echo "skipping"
            continue
        fi
    fi

    echo "copying ${arr[$i]} -> $F_NAME"
    cp "${arr[$i]}" "$T_PATH/$F_NAME"
    if [ $? -ne 0 ]
    then
        echo "could not copy file ${arr[$i]}"
        echo "skipping"
        continue
    fi

done



if [ ${#FAILURES[@]} -gt 0 ]
then 
    echo "${#FAILURES[@]} files could not be processed"
    for i in "${FAILURES[@]}"
    do
        echo $i
    done
fi