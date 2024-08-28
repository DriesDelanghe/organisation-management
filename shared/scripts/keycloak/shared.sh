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

    local url
    local username
    local password


    url=$keycloak_admin_url
    if [[ "$username" == "" ]]; then
        username="keycloak"
    fi
    if [[ "$password" == "" ]]; then
        password="keycloak"
    fi

    local response
    response=$(curl -s --request POST \
        --url "$url/realms/$realm/protocol/openid-connect/token" \
        --header 'Content-Type: application/x-www-form-urlencoded' \
        --data-urlencode "client_id=admin-cli" \
        --data-urlencode "username=$username" \
        --data-urlencode "password=$password" \
        --data-urlencode "grant_type=password")

    response=$(echo "$response" | jq -r '.')
    log_debug "$response"

    echo "$(echo "$response" | jq -r '.access_token')"
}