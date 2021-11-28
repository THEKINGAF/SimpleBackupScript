#!/bin/bash

# Retrieve arguments
while getopts c:F flag
do
    case "${flag}" in
        c) config_file=${OPTARG};;
        F) full_backup=true;;
    esac
done

# Stop script on error
set -o pipefail -e

# Create temp folder
tmp_dir=$(mktemp -d -t backup-XXXXXXXXXX)

# Parse config file and set variables
if [[ ! -f "$config_file" ]]; then
    >&2 echo "ERROR: config file not found"
    exit 1
fi
date=$(date +"%Y%m%d_%H%M")
readarray -t source_folders < <(jq -r '.source_folders[]' "$config_file")
index_file=$( jq -r .index_file "$config_file" )
if [[ ! -f "$index_file" ]]; then
    full_backup=true
fi
output_file=$tmp_dir"/"
output_file+="$( jq -r .backup_prefix "$config_file" )_$date"
if  [ "$full_backup" = true ]; then
    output_file+="_F" # set flag "F" for Full backup
else
    output_file+="_I" # set flag "I" for Incremental backup
fi
output_file+=".tar.gz.pgp"
bucket=$( jq -r .bucket "$config_file" )
pgp_recipient=$( jq -r .pgp_recipient "$config_file" )

# Removing index_file in order to force tar to create a full backup
if  [ "$full_backup" = true ]; then
    rm -f "$index_file"
fi

# Create archive, create/update index file and encrypt
tar --create --gzip --listed-incremental="$index_file" "${source_folders[@]}" | gpg --output "$output_file" --encrypt --recipient "$pgp_recipient"

echo "archiving and encryption finished"

# Upload
gsutil cp "$output_file" "gs://$bucket/"

echo "upload finished"

# Remove local backup file
rm "$output_file"

# Unset "stop script on error"
set +o pipefail +e

rm -rf $tmp_dir

exit 0
