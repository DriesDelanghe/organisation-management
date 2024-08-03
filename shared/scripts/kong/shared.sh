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

get_consumers_acls_url() {
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