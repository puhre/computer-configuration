#! /bin/bash

## This file installs all tracked files on the local system
set -e

## Defaults
DRY_RUN=true
INSTALL=false
UPDATE=true
GROUP=


CONF_FILE_ORIG=./tracked_files.yaml
export CONF_FILE=./tracked_files.yaml.tmp
cat $CONF_FILE_ORIG | envsubst > $CONF_FILE

source src/helper_functions.sh

parse_args $@
repo_files=(`yq -r ".${GROUP}[].local" ${CONF_FILE}`)

for i in `seq 0 $(( ${#repo_files[@]} - 1 ))`; do
    repo_file="${repo_files[$i]}"
    host_file=`yq -r ".${GROUP}[$i].host" ${CONF_FILE}`

    if [[ $INSTALL == true ]]; then
        copy_from_to $repo_file $host_file
    elif [[ $UPDATE == true ]]; then
        copy_from_to $host_file $repo_file
    else
        error "ERROR"
        break
    fi
done

rm $CONF_FILE
