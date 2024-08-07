#!/bin/bash

plugin() {
    if [[ "$1" == "" ]]; then
        plugin_usage
        exit 1
    fi

    local result
    
    case $1 in
        add )
            shift
            result=$(plugin_add "$@")
            ;;
        get )
            shift
            result=$(plugin_get "$@")
            ;;
        -l | --list )
        shift
            result=$(plugin_list "$@")
            ;;
        -h | --help )
            plugin_usage
            exit 0
            ;;
        * )
            plugin_usage
            exit 1
    esac

    echo "$result"
}

plugin_list() {

    local workspace_name

    while [[ "$1" != "" ]]; do
        case $1 in
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            * )
                plugin_list_usage
                exit 1
        esac
        shift
    done

    log_info "Listing all plugins"
    local response
    local status_code
    local path

    if [[ "$workspace_name" != "" ]]; then
        path=$(get_workspace_plugin_path "$workspace_name")
    else
        path=$(get_plugin_path)
    fi

    response=$(do_kong_request -m GET -p "$path")
    status_code=$?

    if [[ $status_code -ne 0 ]]; then
        log_error "Failed to list plugins"
        exit 1
    fi

    response=$(echo "$response" | jq -r '.data[]')
    log_debug "$response"

    echo "$response"
}

plugin_add() {
    if [[ "$1" == "" ]]; then
        plugin_add_usage
        exit 1
    fi

    local data
    data=()
    local plugin_name
    local route_name
    local service_name
    local workspace_name
    local tags
    tags=()


    while [[ "$1" != "" ]]; do
        case $1 in
            -n | --name )
                shift
                plugin_name=$1
                ;;
            -s | --service )
                shift
                service_name=$1
                ;;
            -r | --route )
                shift
                route_name=$1
                ;;
            -d | --data )
                shift
                data+=("$1")
                ;;
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            -t | --tags )
                shift
                tags+=("$1")
                ;;
            * )
                plugin_add_usage
                exit 1
            esac
            shift
        done
        
    if [[ "$plugin_name" == "" ]]; then
        log_error "Plugin name is required."
        log_info ""
        plugin_add_usage
        exit 1
    fi

    if [[ "$service_name" == "" && "$route_name" != "" ]]; then
        log_error "Service name is required when providing a route."
        log_info ""
        plugin_add_usage
        exit 1
    fi

    local response
    local status_code
    local path

    if [[ "$service_name" == "" && "$route_name" == "" ]]; then
        if [[ "$workspace_name" != "" ]]; then
            path=$(get_workspace_plugin_path "$workspace_name")
        else
            path=$(get_plugin_path)
        fi
    elif [[ "$route_name" == "" ]]; then
        if [[ "$workspace_name" != "" ]]; then
            path=$(get_workspace_service_plugin_path "$workspace_name" "$service_name")
        else
            path=$(get_services_plugin_path "$service_name")
        fi
    else
        if [[ "$workspace_name" != "" ]]; then
            path=$(get_workspace_service_route_plugin_path "$workspace_name" "$service_name" "$route_name")
        else
            path=$(get_service_route_plugin_path "$service_name" "$route_name")
        fi
    fi

    arguments=()
    for data in "${data[@]}"; do
        arguments+=("--data $data")
    done

    response=$(do_kong_request -m POST -p "$path" -d "name=$plugin_name" -d "tags=$(IFS=,; echo "${tags[*]}")" ${arguments[*]})
    status_code=$?

    if [[ $status_code -ne 0 ]]; then
        log_error "Failed to add plugin $plugin_name"
        exit 1
    fi

    log_success "Plugin $plugin_name added successfully"

    response=$(echo "$response" | jq -r '.')
    log_debug "$response"

    echo "$response"
}

plugin_get() {
    if [[ "$1" == "" ]]; then
        plugin_get_usage
        exit 1
    fi

    local plugin_name
    local service_name
    local route_name
    local workspace_name

    while [[ "$1" != "" ]]; do
        case $1 in
            -n | --name )
                shift
                plugin_name=$1
                ;;
            -s | --service )
                shift
                service_name=$1
                ;;
            -r | --route )
                shift
                route_name=$1
                ;;
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            * )
                plugin_get_usage
                exit 1
            esac
            shift
        done

    if [[ "$plugin_name" == "" ]]; then
        log_error "Plugin name is required."
        log_info ""
        plugin_get_usage
        exit 1
    fi

    if [[ "$service_name" == "" && "$route_name" != "" ]]; then
        log_error "Service name is required when providing a route."
        log_info ""
        plugin_get_usage
        exit 1
    fi

    local response
    local status_code
    local path

    if [[ "$service_name" == "" && "$route_name" == "" ]]; then
        if [[ "$workspace_name" != "" ]]; then
            path=$(get_workspace_plugin_path "$workspace_name")
        else
            path=$(get_plugin_path)
        fi
    elif [[ "$route_name" == "" ]]; then
        if [[ "$workspace_name" != "" ]]; then
            path=$(get_workspace_service_plugin_path "$workspace_name" "$service_name")
        else
            path=$(get_services_plugin_path "$service_name")
        fi
    else
        if [[ "$workspace_name" != "" ]]; then
            path=$(get_workspace_service_route_plugin_path "$workspace_name" "$service_name" "$route_name")
        else
            path=$(get_service_route_plugin_path "$service_name" "$route_name")
        fi
    fi

    response=$(do_kong_request -m GET -p "$path" | jq -r '.data[] | select(.name == "'"$plugin_name"'")')
    status_code=$?

    if [[ $status_code -ne 0 ]]; then
        log_error "Failed to get plugin $plugin_name"
        exit 1
    fi

    response=$(echo "$response" | jq -r '.')
    log_debug "$response"

    echo "$response"
}

plugin_usage() {
    log_info "Usage: kong plugin <command> [options]"
    log_info ""
    log_info "Commands:"
    log_info "  add [options]                   Add a plugin to a service or route"
    log_info "  get [options]                   Get a plugin by name"
    log_info "  -l, --list                      List all plugins"
    log_info ""
    log_info "Options:"
    log_info "  -h, --help                      Display this help message"
}

plugin_add_usage() {
    log_info "Usage: kong plugin add [options]"
    log_info ""
    log_info "Options:"
    log_info "  -n, --name <plugin_name>        The name of the plugin"
    log_info "  -s, --service <service_name>    The name of the service"
    log_info "  -r, --route <route_name>        The name of the route"
    log_info "  -d, --data <data>               The data to be passed to the plugin"
    log_info "  -w, --workspace <workspace>     The workspace name"

}

plugin_get_usage() {
    log_info "Usage: kong plugin get [options]"
    log_info ""
    log_info "Options:"
    log_info "  -n, --name <plugin_name>        The name of the plugin"
    log_info "  -s, --service <service_name>    The name of the service"
    log_info "  -r, --route <route_name>        The name of the route"
    log_info "  -w, --workspace <workspace>     The workspace name"
}
