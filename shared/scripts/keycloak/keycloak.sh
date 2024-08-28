#!/bin/bash

working_dir=$(pwd)

# change working directory to directory of this script
script_dir=$(dirname "${BASH_SOURCE[0]}")
cd "$script_dir" || {
    log_error "Failed to change the directory to $script_dir"
    exit 1
}

source ./shared.sh

cd "$working_dir" || {
    log_error "Failed to change the directory to $working_dir"
    exit 1
}

keycloak() {
    if [[ "$1" == "" ]]; then
        keycloak_usage
        exit 1
    fi

    local result
    
    case $1 in
        # add )
        #     shift
        #     result=$(keycloak_add "$@")
        #     ;;
        # get )
        #     shift
        #     result=$(keycloak_get "$@")
        #     ;;
        # -l | --list )
        # shift
        #     result=$(keycloak_list "$@")
        #     ;;
        -h | --help )
            keycloak_usage
            exit 0
            ;;
        * )
            keycloak_usage
            exit 1
    esac

    echo "$result"
}

keycloak_usage() {
    echo "Usage: keycloak [command]"
    echo
    echo "Commands:"
    # echo "  add [name] [url] [username] [password]  Add a new keycloak instance"
    # echo "  get [name]                             Get a keycloak instance"
    # echo "  -l, --list                             List all keycloak instances"
    echo "  -h, --help                             Display this help message"
}