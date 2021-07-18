#!/bin/bash

while getopts c: flag
do
    case "${flag}" in
        c) config_file=${OPTARG};;
    esac
done

index_file=$( jq -r .index_file "$config_file" )
output_temp_file="$( jq -r .backup_prefix "$config_file" )backup.tar"
source_folders=$( jq -r '.source_folders[]' "$config_file" | sed ':a;N;$!ba;s/\n/ /g' )

tar --create --listed-incremental=$index_file --verbose --file=$output_temp_file $source_folders
gzip -kf $output_temp_file
