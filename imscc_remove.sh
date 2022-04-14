#!/usr/bin/env bash


FILE_TYPES=()
TOTALS=()


my_help() {
    echo "usage:
    
    $0 -l|-r ["pattern"] input.imscc"
}

abort() {
    echo "$1"
    [ -z $2 ] || my_help
    exit $2
}


count_types() {
    # count files by type in a path
    # ARGS:
    # 1) path
    find $1 -type f |  egrep -o '\.[^/.]+$' | sort | uniq -c | sort -n
}

get_types() {
    # get list of all the types 
    # ARGS: 
    # 1) Path
    IFS=$'\n' read -r -d '' -a FILE_TYPES < <( find $1 -type f | egrep -o '\.[^/.]+$' |sort | uniq && printf '\0' )
    # find $1 -type f | egrep -o '\.[^/.]+$' |sort | uniq
}

get_total() {
    # get a total disk usage in a path based on a glob expression
    # ARGS:
    # 1) Path
    # 2) glob expression e.g. *.pdf
    r=$(find $1 \( -iname "$2"  \) -type f -exec du -c {} + | grep total$ | cut -f1 | awk '{ total += $1 }; END { print total }')
    echo $r
}

totals_by_type() {
    # show the total disk usage in a path for all file types in a path
    # ARGS:
    # 1) Path
    get_types $1
    for i in ${FILE_TYPES[@]}
    do
        t=$(get_total $1 "*$i")

        human="$i:$((t/1024))MB"

        TOTALS+=("$human")
    done

    for j in ${TOTALS[@]}
    do
        echo "$j"
    done
}

find_replace_type() {
    # find and replace a file type in a path and does the following:
    # - makes copy of file to temporary directory
    # - replaces file with .txt file that references original
    # - replaces references in manifest .xml file with .txt files
    # ARGS:
    # 1) path
    # 2) glob expression e.g. *.pdf

    MANIFEST="imsmanifest.xml"
    SOURCE_PATH=$1
    EXTENSION=$2
    TEMP_PATH="./temp_path"


    [ -f $SOURCE_PATH/$MANIFEST ] || abort "could not find manifest file in path: '$1'" 1
    [ -z $EXTENSION ] && abort "no filetype specified" 1

    # change all the references in the manifest to .txt files
    echo "updating manfiest file for filetypes: $2"
    sed -i'' -e "s/\(<file href=.*\)\(\.$EXTENSION\)/\1\.txt/g" $SOURCE_PATH/$MANIFEST

    # copy  out the original files before modifying
    echo "copying file that match $EXTENSION to $TEMP_PATH"
    find $SOURCE_PATH -type f -name "*.$EXTENSION" -exec cp {} $TEMP_PATH \;

    # replace the contents of files with a short string
    echo "replacing contents of files that match $EXTENSION"

    #
    find $SOURCE_PATH -type f -name "*.$EXTENSION" -exec bash -c 'file="{}"; echo "this file was removed from this archive. Original filename: $(basename "$file")"> "$file" ' \;
    echo "renaming files that match $EXTENSION to '.txt'"
    
    
    find $SOURCE_PATH -type f -name "*.$EXTENSION" -exec bash -c 'file="{}"; mv "$file" "$(echo "$file" | sed 's/\.$EXTENSION/\.txt/g')"  '   \;

    # 
}

package() {

}

find_replace_type $1 $2

# totals_by_type $1