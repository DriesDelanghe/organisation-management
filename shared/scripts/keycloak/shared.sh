#!/bin/bash

keycloak_realm_path="realms"

keycloak_admin_url="http://localhost:8080"
keycloak_realm_url="$keycloak_admin_url/$keycloak_realm_path"

get_keycloak_url() {
    echo "$keycloak_admin_url"
}

get_realm_url() {
    if [[ "$1" == "" ]]; then
        echo "$keycloak_realm_url"
    else
        echo "$keycloak_realm_url/$1"
    fi
}

get_token() {

    local realm
    local username
    local password

    while [[ "$1" != "" ]]; do
        case $1 in
            -r | --realm )
                shift
                realm=$1
                ;;
            -u | --username )
                shift
                username=$1
                ;;
            -p | --password )
                shift
                password=$1
                ;;
            * )
                echo "Invalid argument: $1"
                exit 1
        esac
        shift
    done

    if [[ "$realm" == "" ]]; then
        realm="master"
    fi

    work_dir=$(pwd)
    cd "$(dirname "${BASH_SOURCE[0]}")" || {
        echo "Failed to change the directory to $(dirname "$0")"
        exit 1
    }
    local url
    local username
    local password
    if [[ -f "./keycloak-config,json" ]]; then
        local config
        config=$(cat ./keycloak-config.json)
        url=$(echo "$config" | jq -r '.url')
        if [[ "$username" == "" ]]; then
            username=$(echo "$config" | jq -r '.credentials.username')
        fi
        if [[ "$password" == "" ]]; then
            password=$(echo "$config" | jq -r '.credentials.password')
        fi
    else
        url=$keycloak_admin_url
        if [[ "$username" == "" ]]; then
            username="keycloak"
        fi
        if [[ "$password" == "" ]]; then
            password="keycloak"
        fi
    fi

    cd "$work_dir" || {
        echo "Failed to change the directory to $work_dir"
        exit 1
    }

    local response
    response=$(curl -s --request POST \
        --url "$url/realms/$realm/protocol/openid-connect/token" \
        --header 'Content-Type: application/x-www-form-urlencoded' \
        --data-urlencode "client_id=admin-cli" \
        --data-urlencode "username=$username" \
        --data-urlencode "password=$password" \
        --data-urlencode "grant_type=password" | jq -r '.access_token')

    echo "$response"
}
