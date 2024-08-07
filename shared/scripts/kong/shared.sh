#!/bin/bash

kong_plugin_path="plugins"
kong_services_path="services"
kong_route_path="routes"
kong_consumers_path="consumers"
kong_workspace_path="workspaces"
kong_consumer_groups_path="consumer_groups"
kong_acls_path="acls"

key_auth_path="key-auth"

kong_api_key_header_name="kal-api-key"

# URLs
kong_admin_url="http://localhost:8001"
kong_plugin_url="$kong_admin_url/$kong_plugin_path"
kong_services_url="$kong_admin_url/$kong_services_path"
kong_consumers_url="$kong_admin_url/$kong_consumers_path"

get_kong_url() {
    echo "$kong_admin_url"
}

# get urls

get_workspace_url() {
    if [[ "$1" == "" ]]; then
        echo "$kong_admin_url/$kong_workspace_path"
    else
        echo "$kong_admin_url/$kong_workspace_path/$1"
    fi
}

get_plugin_url() {

    if [[ "$1" == "" ]]; then
        echo "$kong_plugin_url"
    else 
        echo "$kong_plugin_url/$1"
    fi
}

get_workspace_plugin_url() {
    if [[ "$1" == "" ]]; then
        log_error "Workspace name is required"
        exit 1
    else
        echo "$(get_workspace_url "$1")/$kong_plugin_path"
    fi
}

get_services_url() {
    if [[ "$1" == "" ]]; then
        echo "$kong_services_url"
    else 
        echo "$kong_services_url/$1"
    fi
}

get_workspace_service_url() {
    if [[ "$1" == "" ]]; then
        log_error "Workspace name is required"
        exit 1
    elif [[ "$2" == "" ]]; then
        echo "$(get_workspace_url "$1")/$kong_services_path"
    else
        echo "$(get_workspace_url "$1")/$kong_services_path/$2"
    fi
}

get_service_route_url() {
    # need 2 arguments, first is the service name, second is the route
    if [[ "$1" == "" ]]; then
        log_error "Service name is required"
        exit 1
    elif [[ "$2" == "" ]]; then
        echo "$(get_services_url "$1")/$kong_route_path"
    else 
        echo "$(get_services_url "$1")/$kong_route_path/$2"
    fi
}

get_workspace_service_route_url() {
    if [[ "$1" == "" || "$2" == "" ]]; then
        log_error "Workspace name and service name are required"
        exit 1
    elif [[ "$3" == "" ]]; then
        echo "$(get_workspace_service_url "$1" "$2")/$kong_route_path"
    else
        echo "$(get_workspace_service_url "$1" "$2")/$kong_route_path/$3"
    fi
}

get_services_plugin_url() {
    if [[ "$1" == "" ]]; then
        log_error "Service name is required"
        exit 1
    else 
        echo "$(get_services_url "$1")/$kong_plugin_path"
    fi
}

get_workspace_service_plugin_url() {
    if [[ "$1" == "" || "$2" == "" ]]; then
        log_error "Workspace name and service name are required"
        exit 1
    else 
        echo "$(get_workspace_service_url "$1" "$2")/$kong_plugin_path"
    fi
}

get_service_route_plugin_url() {
    # need 2 arguments, first is the service name, second is the route
    if [[ "$1" == "" || "$2" == "" ]]; then
        log_error "Service name and route name are required"
        exit 1
    else 
        echo "$(get_service_route_url "$1" "$2")/$kong_plugin_path"
    fi
}

get_workspace_service_route_plugin_url() {
    if [[ "$1" == "" || "$2" == "" || "$3" == "" ]]; then
        log_error "Workspace name, service name, and route name are required"
        exit 1
    else 
        echo "$(get_workspace_service_route_url "$1" "$2" "$3")/$kong_plugin_path"
    fi
}

get_consumers_url() {
    if [[ "$1" == "" ]]; then
        echo "$kong_consumers_url"
    else 
        echo "$kong_consumers_url/$1"
    fi
}

get_workspace_consumer_url() {
    if [[ "$1" == "" ]]; then
        log_error "Workspace name is required"
        exit 1
    else
        echo "$(get_workspace_url "$1")/$kong_consumers_path"
    fi
}

get_consumers_key_url() {
    if [[ "$1" == "" ]]; then
        log_error "Consumer id is required"
        exit 1
    else
        echo "$(get_consumers_url "$1")/$key_auth_path"
    fi
}

get_workspace_consumers_key_url() {
    if [[ "$1" == "" || "$2" == "" ]]; then
        log_error "Workspace name and consumer id are required"
        exit 1
    else
        echo "$(get_workspace_consumer_url "$1")/$key_auth_path"
    fi
}

get_consumers_group_url() {
    if [[ "$1" == "" ]]; then
        echo "$kong_admin_url/$kong_consumer_groups_path"
    else
        echo "$kong_admin_url/$kong_consumer_groups_path/$1"
    fi
}

get_workspace_consumers_group_url() {
    if [[ "$1" == "" ]]; then
        log_error "Workspace name is required"
        exit 1
    elif [[ "$2" == "" ]]; then
        echo "$(get_workspace_url "$1")/$kong_consumer_groups_path"
    else
        echo "$(get_workspace_url "$1")/$kong_consumer_groups_path/2"
    fi
}

get_consumers_acl_url() {
    if [[ "$1" == "" ]]; then
        log_error "Consumer username is required"
        exit 1
    else
        echo "$(get_consumers_url "$1")/$kong_acls_path"
    fi
}

get_workspace_consumer_acls_url() {
    if [[ "$1" == "" || "$2" == "" ]]; then
        log_error "Workspace name and consumer username are required"
        exit 1
    else
        echo "$(get_workspace_consumer_url "$1")/$kong_acls_path"
    fi
}

# get paths

get_kong_path() {
    echo ""
}

get_workspace_path() {
    if [[ "$1" == "" ]]; then
        echo "$kong_workspace_path"
    else
        echo "$kong_workspace_path/$1"
    fi
}

get_plugin_path() {

    if [[ "$1" == "" ]]; then
        echo "$kong_plugin_path"
    else 
        echo "$kong_plugin_path/$1"
    fi
}

get_workspace_plugin_path() {
    if [[ "$1" == "" ]]; then
        log_error "Workspace name is required"
        exit 1
    else
        echo "$(get_workspace_path "$1")/$kong_plugin_path"
    fi
}

get_services_path() {
    if [[ "$1" == "" ]]; then
        echo "$kong_services_path"
    else 
        echo "$kong_services_path/$1"
    fi
}

get_workspace_services_path() {
    if [[ "$1" == "" ]]; then
        log_error "Workspace name is required"
        exit 1
    elif [[ "$2" == "" ]]; then
        echo "$(get_workspace_path "$1")/$kong_services_path"
    else
        echo "$(get_workspace_path "$1")/$kong_services_path/$2"
    fi
}

get_services_route_path() {
    # need 2 arguments, first is the service name, second is the route
    if [[ "$1" == "" ]]; then
        log_error "Service name is required"
        exit 1
    elif [[ "$2" == "" ]]; then
        echo "$(get_services_path "$1")/$kong_route_path"
    else 
        echo "$(get_services_path "$1")/$kong_route_path/$2"
    fi
}

get_workspace_services_route_path() {
    if [[ "$1" == "" || "$2" == "" ]]; then
        log_error "Workspace name and service name are required"
        exit 1
    elif [[ "$3" == "" ]]; then
        echo "$(get_workspace_service_path "$1" "$2")/$kong_route_path"
    else
        echo "$(get_workspace_service_path "$1" "$2")/$kong_route_path/$3"
    fi
}

get_services_plugin_path() {
    if [[ "$1" == "" ]]; then
        log_error "Service name is required"
        exit 1
    else 
        echo "$(get_services_path "$1")/$kong_plugin_path"
    fi
}

get_workspace_service_plugin_path() {
    if [[ "$1" == "" || "$2" == "" ]]; then
        log_error "Workspace name and service name are required"
        exit 1
    else 
        echo "$(get_workspace_service_path "$1" "$2")/$kong_plugin_path"
    fi
}

get_service_route_plugin_path() {
    # need 2 arguments, first is the service name, second is the route
    if [[ "$1" == "" || "$2" == "" ]]; then
        log_error "Service name and route name are required"
        exit 1
    else 
        echo "$(get_services_route_path "$1" "$2")/$kong_plugin_path"
    fi
}

get_workspace_service_route_plugin_path() {
    if [[ "$1" == "" || "$2" == "" || "$3" == "" ]]; then
        log_error "Workspace name, service name, and route name are required"
        exit 1
    else 
        echo "$(get_workspace_services_route_path "$1" "$2" "$3")/$kong_plugin_path"
    fi
}

get_consumer_path() {
    if [[ "$1" == "" ]]; then
        echo "$kong_consumers_path"
    else 
        echo "$kong_consumers_path/$1"
    fi
}

get_workspace_consumer_path() {
    if [[ "$1" == "" ]]; then
        log_error "Workspace name is required"
        exit 1
    else
        echo "$(get_workspace_path "$1")/$kong_consumers_path"
    fi
}

get_consumer_key_path() {
    if [[ "$1" == "" ]]; then
        log_error "Consumer id is required"
        exit 1
    else
        echo "$(get_consumer_path "$1")/$key_auth_path"
    fi
}

get_workspace_consumer_key_path() {
    if [[ "$1" == "" || "$2" == "" ]]; then
        log_error "Workspace name and consumer id are required"
        exit 1
    else
        echo "$(get_workspace_consumer_path "$1")/$key_auth_path"
    fi
}

get_consumers_group_path() {
    if [[ "$1" == "" ]]; then
        echo "$kong_consumer_groups_path"
    else
        echo "$kong_consumer_groups_path/$1"
    fi
}

get_workspace_consumers_group_path() {
    if [[ "$1" == "" ]]; then
        log_error "Workspace name is required"
        exit 1
    elif [[ "$2" == "" ]]; then
        echo "$(get_workspace_path "$1")/$kong_consumer_groups_path"
    else
        echo "$(get_workspace_path "$1")/$kong_consumer_groups_path/2"
    fi
}

get_consumers_acl_path() {
    if [[ "$1" == "" ]]; then
        log_error "Consumer username is required"
        exit 1
    else
        echo "$(get_consumer_path "$1")/$kong_acls_path"
    fi
}

get_workspace_consumer_acl_path() {
    if [[ "$1" == "" || "$2" == "" ]]; then
        log_error "Workspace name and consumer username are required"
        exit 1
    else
        echo "$(get_workspace_consumer_path "$1")/$kong_acls_path"
    fi
}


do_kong_request() {

    local method
    local path
    local data=()
    local headers=()

    while [[ "$1" != "" ]]; do
        case $1 in
            -m | --method )
                shift
                method=$1
                ;;
            -p | --path )
                shift
                path=$1
                ;;
            -d | --data )
                shift
                data+=("$1")
                ;;
            -h | --header )
                shift
                headers+=("$1")
                ;;
            --help )
                do_kong_request_usage
                exit 0
                ;;
            * )
                log_error "Unknown argument: $1"
                exit 1
        esac
        shift
    done

    if [[ "$method" == "" ]]; then
        log_error "Method is required"
        do_kong_request_usage
        exit 1
    fi

    # check if the file kong-config.json exists in the directory of this script
    work_dir=$(pwd)
    cd "$(dirname "${BASH_SOURCE[0]}")" || {
        log_error "Failed to change the directory to $(dirname "${BASH_SOURCE[0]}")"
        exit 1
    }

    local base_url=$kong_admin_url
    local credentials=()

    if [[ -f "./output/kong-config.json" ]]; then
        local config
        config=$(cat kong-config.json)
        base_url=$(echo "$config" | jq -r '.url')
        mapfile -t credentials < <(echo "$config" | jq -r '.credentials[]')
    fi

    cd $work_dir || {
        log_error "Failed to change the directory to $work_dir"
        exit 1
    }

    local response
    local status_code

    for credential in "${credentials[@]}"; do
        local type
        type=$(echo "$credential" | jq -r '.type')
        case $type in
            "api-key" )
                headers+=("$(echo "$credential" | jq -r '.header'): $(echo "$credential" | jq -r '.key')")
                ;;
            * )
                log_error "Unknown credential type: $type"
                exit 1
        esac
    done

    arguments=()
    if [[ "${#headers[@]}" -gt 0 ]]; then
        for header in "${headers[@]}"; do
            arguments+=("--header $header")
        done
    fi

    if [[ "${#data[@]}" -gt 0 ]]; then
        for data in "${data[@]}"; do
            arguments+=("--data $data")
        done
    fi

    if [[ "${#arguments[@]}" -gt 0 ]]; then
        response=$(curl -s --request "$method" \
            --url "$base_url/$path" \
            ${arguments[*]})
        status_code=$?
    else
        response=$(curl -s --request "$method" \
            --url "$base_url/$path")
        status_code=$?

    fi


    if [[ $status_code -ne 0 ]]; then
        log_error "Failed to make request for path $path"
        exit 1
    fi

    echo "$response"
}

do_kong_request_usage() {
    echo "Usage: do_kong_request -m <method> [-p <path>] [-d <data>] [-h <header>]"
    echo ""
    echo "Options:"
    echo "  -m, --method <method>  The HTTP method to use for the request"
    echo "  -p, --path <path>      The path to make the request to"
    echo "  -d, --data <data>      The data to send with the request"
    echo "  -h, --header <header>  The header to send with the request"
    echo "  --help                 Display this help message"
}