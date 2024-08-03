#!/bin/bash

config() {
    local result

    case $1 in
        -h | --help )
            config_usage
            exit 0
            ;;
        get )
            shift
            result=$(config_get "$@")
            ;;
        * )
            config_usage
            exit 1
    esac

    echo "$result"
}

config_get() {
    local response
    response=$(curl -s --request GET \
        --url "$(get_kong_url)" | jq -r '.configuration')

    echo "$response"

}

config_usage() {
    echo "Usage: kong config [get]"
    echo ""
    echo "Options:"
    echo "  get          Get the configuration of Kong"
    echo "  -h, --help   Show help"
}