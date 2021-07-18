#!/bin/bash

while getopts c:F flag
do
    case "${flag}" in
        c) config_file=${OPTARG};;
        F) full_backup=true;;
    esac
done

# Parse config file and set variables
date=$(date +"%Y%m%d_%H%M")
source_folders=$( jq -r '.source_folders[]' "$config_file" | sed ':a;N;$!ba;s/\n/ /g' )
index_file=$( jq -r .index_file "$config_file" )
if [[ ! -f "$index_file" ]]; then
    full_backup=true
fi
output_file="$( jq -r .backup_prefix "$config_file" )_$date"
if  [ "$full_backup" = true ]; then
    output_file+="_F" # set flag "F" for Full backup
else
    output_file+="_I" # set flag "I" for Incremental backup
fi
output_file+=".tar.gz"

# Removing index_file in order to force tar to create a full backup
if  [ "$full_backup" = true ]; then
    rm -f $index_file
fi

# Create archive and create/update index file
tar --create --gzip --listed-incremental=$index_file --verbose --file=$output_file $source_folders
