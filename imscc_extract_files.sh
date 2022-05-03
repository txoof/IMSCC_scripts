#!/usr/bin/env bash
TEMPDIR=$(mktemp -d)
INPUT_FILE=$1
OUTPUT_PATH=./temp_path/foo
MANIFEST_FILE="imsmanifest.xml"

slugify () {
    echo "$1" | iconv -c -t ascii//TRANSLIT | sed -E 's/[~^]+//g' | sed -E 's/[^a-zA-Z0-9]+/_/g' | sed -E 's/^-+|-+$//g' | tr A-Z a-z
}

abort() {
    echo $1
    echo "aborting execution"
    exit
}


[ -z $1 ] && abort "Provide an IMSCC file by dropping in this window or using: $0 /path/to/foo.imscc"

tar xvzf $INPUT_FILE -C $TEMPDIR > $TEMPDIR/extraction.log 2>&1

NODES=()
while IFS= read -r line; do
    NODES+=( "$line" )
done < <( xpath -q -e "//lomm:string/text()" $TEMPDIR/$MANIFEST_FILE )

# teacher name
T_NAME=$(slugify "${NODES[1]}")

# course name
C_NAME=$(slugify "${NODES[0]}")

echo "teacher: $T_NAME; course name: $C_NAME"

OUTPUT_PATH=$OUTPUT_PATH/$T_NAME.$C_NAME

if [ ! -d "$OUTPUT_PATH" ] 
then
    mkdir "$OUTPUT_PATH"
    if [ $? -ne 0 ]
    then
        echo "could not create directory: $T_PATH"
        echo "skipping"
    fi
fi

# find $TEMPDIR -type f -not -name "*.xml" -not -name "*.html" -exec mv {} $OUTPUT_PATH \;
find $TEMPDIR -type f -not -name "*.xml" -not -name "*.html" | while read FILE ; do newfile="$(echo ${FILE} | sed  -E -e 's#(.*RES-[0-9a-zA-z]+/)([0-9a-zA-Z]+)(-)(.*)(\.[a-zA-Z0-9]{2,}$)#\4-\2\5#')" ; mv "${FILE}"  "${OUTPUT_PATH}/${newfile}" ; done

echo "All regular files from $INPUT_FILE were extracted and placed in $OUTPUT_PATH. NOTE: no .html or .xml files were included."