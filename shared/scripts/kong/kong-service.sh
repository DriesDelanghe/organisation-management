#!/bin/bash

service() {
    if [[ "$1" == "" ]]; then
        service_usage
        exit 1
    fi

    local result

    case $1 in
        add )
            shift
            result=$(service_add "$@")
            ;;
        get )
            shift
            result=$(service_get "$@")
            ;;
        route )
            shift
            result=$(service_route "$@")
            ;;
        -h | --help )
            service_usage
            exit 0
            ;;
        -l | --list )
            result=$(service_list "$@")
            ;;
        * )
            service_usage
            exit 1
    esac

    echo "$result"
}

service_list() {

    local workspace_name

    while [[ "$1" != "" ]]; do
        case $1 in
            -h | --help )
                service_list_usage
                exit 0
                ;;
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            * )
                service_list_usage
                exit 1
        esac
        shift
    done

    log_info "Listing all services"
    
    local response
    local status_code
    local path

    if [[ "$workspace_name" != "" ]]; then
        path=$(get_workspace_services_path "$workspace_name")
    else
        path=$(get_services_path)
    fi

    response=$(do_kong_request -m GET -p "$path")
    status_code=$?
    
    if [[ $status_code -ne 0 ]]; then
        log_error "Failed to list services"
        exit 1
    fi

    log_success "Services listed successfully"

    response=$(echo "$response" | jq -r '.data[]')
    log_debug "$response"

    echo "$response"
}

service_add() {
    if [[ "$1" == "" ]]; then
        service_add_usage
        exit 1
    fi
    
    local name
    local backend_url
    local workspace_name
    local tags
    tags=()

    while [[ "$1" != "" ]]; do
        case $1 in
            -n | --name )
                shift
                name=$1
                ;;
            -u | --url )
                shift
                backend_url=$1
                ;;
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            -t | --tag )
                shift
                tags+=("$1")
                ;;
            * )
                service_add_usage
                exit 1
        esac
        shift
    done

    if [[ "$name" == "" || "$backend_url" == "" ]]; then
        log_error "Name and URL are required."
        log_info ""
        service_add_usage
        exit 1
    fi

    log_info "Creating service $name with url $backend_url"
    local response
    local status_code
    local path

    if [[ "$workspace_name" != "" ]]; then
        path=$(get_workspace_services_path "$workspace_name")
    else
        path=$(get_services_path)
    fi

    response=$(do_kong_request -m POST -p "$path" -d "name=$name" -d "url=$backend_url" -d "tags[]=$(IFS=,; echo "${tags[*]}")")
    status_code=$?

    if [[ $status_code -ne 0 ]]; then
        log_error "Failed to create service $name"
        exit 1
    fi

    log_success "Service $name created successfully"

    response=$(echo "$response" | jq -r '.')
    log_debug "$response"

    echo "$response"
}

service_get() {
    if [[ "$1" == "" ]]; then
        service_get_usage
        exit 1
    fi

    local name
    local workspace_name

    while [[ "$1" != "" ]]; do
        case $1 in
            -n | --name )
                shift
                name=$1
                ;;
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            * )
                service_get_usage
                exit 1
        esac
        shift
    done

    if [[ "$name" == "" ]]; then
        log_error "Name is required."
        log_info ""
        service_get_usage
        exit 1
    fi

    log_info "Getting service $name"
    local response
    local status_code
    local path

    if [[ "$workspace_name" != "" ]]; then
        path=$(get_workspace_services_path "$workspace_name" "$name")
    else
        path=$(get_services_path "$name")
    fi

    response=$(do_kong_request -m GET -p "$path")
    status_code=$?

    if [[ $status_code -ne 0 ]]; then
        log_error "Failed to get service $name"
        exit 1
    fi

    log_success "Service $name retrieved successfully"

    response=$(echo "$response" | jq -r '.')

    log_debug "$response"
    echo "$response"
}

service_route() {
    if [[ "$1" == "" ]]; then
        service_route_usage
        exit 1
    fi

    local result

    case $1 in
        add )
            shift
            result=$(service_route_add "$@")
            ;;
        get )
            shift
            result=$(service_route_get "$@")
            ;;
        -h | --help )
            service_route_usage
            exit 0
            ;;
        -l | --list )
            shift
            result=$(service_route_list "$@")
            ;;
        * )
            service_route_usage
            exit 1
    esac

    echo "$result"
}

service_route_list() {

    local workspace_name
    local service_name

    while [[ "$1" != "" ]]; do
        case $1 in
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            -h | --help )
                service_route_list_usage
                exit 0
                ;;
            -s | --service )
                shift
                service_name=$1
                ;;
            * )
                service_route_list_usage
                exit 1
                ;;
        esac
        shift
    done

    log_info "Listing all routes"
    local response
    local status_code
    local path

    if [[ "$workspace_name" != "" ]]; then
        path=$(get_workspace_services_route_path "$workspace_name" "$service_name")
    else
        path=$(get_services_route_path "$service_name")
    fi

    response=$(do_kong_request -m GET -p "$path")
    status_code=$?

    if [[ $status_code -ne 0 ]]; then
        log_error "Failed to list routes"
        exit 1
    fi

    log_success "Routes listed successfully"

    response=$(echo "$response" | jq -r '.data[]')
    log_debug "$response"

    echo "$response"
}

service_route_add() {
    if [[ "$1" == "" ]]; then
        service_route_add_usage
        exit 1
    fi

    local path
    local path_name
    local service_name
    local workspace_name
    local tags
    tags=()

    while [[ "$1" != "" ]]; do
        case $1 in
            -s | --service )
                shift
                service_name=$1
                ;;
            -n | --path-name )
                shift
                path_name=$1
                ;;
            -p | --path )
                shift
                path=$1
                ;;
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            -t | --tag )
                shift
                tags+=("$1")
                ;;
            * )
                service_route_add_usage
                exit 1
        esac
        shift
    done

    if [[ "$service_name" == "" || "$path" == "" || "$path_name" == "" ]]; then
        log_error "Service name, path, and path name are required."
        log_info ""
        service_route_add_usage
        exit 1
    fi

    log_info "Creating route $path_name for service $service_name"

    local response
    local status_code
    local kong_path

    if [[ "$workspace_name" != "" ]]; then
        kong_path=$(get_workspace_services_route_path "$workspace_name" "$service_name")
    else
        kong_path=$(get_services_route_path "$service_name")
    fi

    response=$(do_kong_request -m POST -p "$kong_path" -d "paths[]=$path" -d "name=$path_name" -d "tags[]=$(IFS=,; echo "${tags[*]}")")
    status_code=$?

    if [[ status_code -ne 0 ]]; then
        log_error "Failed to create route $path_name for service $service_name"
        exit 1
    fi

    log_success "Route $path_name created successfully"

    response=$(echo "$response" | jq -r '.')
    log_debug "$response"

    echo "$response"
}

service_route_get() {
    if [[ "$1" == "" ]]; then
        service_route_get_usage
        exit 1
    fi

    local path_name
    local service_name
    local workspace_name

    while [[ "$1" != "" ]]; do
        case $1 in
            -s | --service )
                shift
                service_name=$1
                ;;
            -n | --path-name )
                shift
                path_name=$1
                ;;
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            * )
                service_route_get_usage
                exit 1
        esac
        shift
    done

    if [[ "$service_name" == "" || "$path_name" == "" ]]; then
        log_error "Service name and path name are required."
        log_info ""
        service_route_get_usage
        exit 1
    fi

    log_info "Getting route $path_name for service $service_name"
    local response
    local status_code
    local path

    if [[ "$workspace_name" != "" ]]; then
        path=$(get_workspace_services_route_path "$workspace_name" "$service_name" "$path_name")
    else
        path=$(get_services_route_path "$service_name" "$path_name")
    fi

    response=$(do_kong_request -m GET -p "$path")
    status_code=$?

    if [[ $status_code -ne 0 ]]; then
        log_error "Failed to get route $path_name for service $service_name"
        exit 1
    fi

    log_success "Route $path_name for service $service_name retrieved successfully"

    response=$(echo "$response" | jq -r '.')
    log_debug "$response"

    echo "$response"
}

service_usage() {

    log_info "Usage: kong service <command> [options]"
    log_info ""
    log_info "Commands:"
    log_info "  -l, --list                      List all services"
    log_info "  add [options]                   Add a new service"
    log_info "  get [options]                   Get a service by name"
    log_info "  route <command> [options]       Manage routes for a service"
    log_info ""
    log_info "Options:"
    log_info "  -h, --help                      Display this help message"

}

service_add_usage() {
    log_info "Usage: kong service add [options]"
    log_info ""
    log_info "Options:"
    log_info "  -n, --name <name>               The name of the service"
    log_info "  -t, --tag <tag>                 A tag for the service"
    log_info "  -u, --url <url>                 The URL of the service"
    log_info "  -w, --workspace <workspace>     The name of the workspace"
}

service_get_usage() {
    log_info "Usage: kong service get [options]"
    log_info ""
    log_info "Options:"
    log_info "  -n, --name <name>               The name of the service"
    log_info "  -w, --workspace <workspace>     The name of the workspace"
}

service_route_usage() {
    log_info "Usage: kong service route <command> [options]"
    log_info ""
    log_info "Commands:"
    log_info "  add [options]                   Add a route to a service"
    log_info "  get [options]                   Get a route by name"
    log_info "  -l, --list                      List all routes"
    log_info ""
    log_info "Options:"
    log_info "  -h, --help                      Display this help message"
}

service_route_add_usage() {
    log_info "Usage: kong service route add [options]"
    log_info ""
    log_info "Options:"
    log_info "  -n, --path-name <path_name>     The name of the path"
    log_info "  -p, --path <path>               The path"
    log_info "  -s, --service <service_name>    The name of the service"
    log_info "  -t, --tag <tag>                 A tag for the route"
    log_info "  -w, --workspace <workspace>     The name of the workspace"

}

service_route_get_usage() {
    log_info "Usage: kong service route get [options]"
    log_info ""
    log_info "Options:"
    log_info "  -s, --service <service_name>    The name of the service"
    log_info "  -n, --path-name <path_name>     The name of the path"
    log_info "  -w, --workspace <workspace>     The name of the workspace"
}