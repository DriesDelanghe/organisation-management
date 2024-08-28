#!/bin/bash

working_dir=$(pwd)

# change working directory to directory of this script
script_dir=$(dirname "${BASH_SOURCE[0]}")
cd "$script_dir" || {
    log_error "Failed to change the directory to $script_dir"
    exit 1
}

# source ../keycloak/keycloak.sh
source ./kong-config.sh
source ./kong-consumer.sh
source ./kong-plugin.sh
source ./kong-service.sh
source ./kong-workspace.sh
source ./shared.sh

cd "$working_dir" || {
    log_error "Failed to change the directory to $working_dir"
    exit 1
}


kong() {

    # read first arguments

    local result

    case $1 in
        service )
            shift
            result=$(service "$@")
            ;;
        plugin )
            shift
            result=$(plugin "$@")
            ;;
        consumer )
            shift
            result=$(consumer "$@")
            ;;
        workspace )
            shift
            result=$(workspace "$@")
            ;;
        config )
            shift
            result=$(config "$@")
            ;;
        -h | --help )
            usage
            exit
            ;;
        * )
            usage
            exit 1
    esac

    echo "$result"
}

usage() {
    # this method will print the usage of this script and what options are considered a valid option, with a short explanation on how it works and what it does
    log_info "Usage: kong <command> [options]"
    log_info ""
    log_info "Commands:"
    log_info "  service [options]           Manage Kong services"
    log_info "  plugin [options]            Manage Kong plugins"
    log_info "  consumer [options]          Manage Kong consumers"
    log_info ""
    log_info "Options:"
    log_info "  -h, --help                  Display this help message"
}