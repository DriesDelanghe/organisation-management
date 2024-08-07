#!/bin/bash

workspace() {
    if [[ "$1" == "" ]]; then
        workspace_usage
        exit 1
    fi
    
    local result

    case $1 in
        add )
            shift
            result=$(workspace_add "$@")
            ;;
        get )
            shift
            result=$(workspace_get "$@")
            ;;
        -l | --list )
            result=$(workspace_list)
            ;;
        * )
            workspace_usage
            exit 1
    esac
    shift

    echo "$result"
}

workspace_list() {
    log_info "Retrieving all workspaces"

    local response
    local status_code

    response=$(do_kong_request -m GET -p "$(get_workspace_path)")
    status_code=$?

    if [[ $status_code -ne 0 ]]; then
        log_error "Failed to list workspaces"
        return 1
    fi

    response=$(echo "$response" | jq -r '.data')
    log_debug "$response"

    log_success "Retrieved all workspaces successfully"

    echo "$response"
}

workspace_add() {
    if [[ "$1" == "" ]]; then
        workspace_add_usage
        exit 1
    fi

    local workspace_name

    while [[ "$1" != "" ]]; do
        case $1 in
            -n | --name )
                shift
                workspace_name=$1
                ;;
            * )
                workspace_add_usage
                exit 1
        esac
        shift
    done

    if [[ "$workspace_name" == "" ]]; then
        log_error "Workspace name is required"
        log_info ""
        workspace_add_usage
        exit 1
    fi

    log_info "Adding workspace $workspace_name"

    local response
    local status_code

    response=$(do_kong_request -m POST -p "$(get_workspace_path)" -d "name=$workspace_name")
    status_code=$?

    if [[ $status_code != 0 ]]; then
        log_error "Failed to create workspace $workspace_name"
        return 1
    fi

    response=$(echo "$response" | jq -r '.')
    log_debug "$response"

    log_success "Workspace $workspace_name created successfully"
    echo "$response"
}

workspace_get() {
    if [[ "$1" == "" ]]; then
        workspace_get_usage
        exit 1
    fi

    local workspace_name=$1

    while [[ "$1" != "" ]]; do
        case $1 in
            -n | --name )
                shift
                workspace_name=$1
                ;;
            * )
                workspace_get_usage
                exit 1
        esac
        shift
    done

    if [[ "$workspace_name" == "" ]]; then
        log_error "Workspace name is required"
        log_info ""
        workspace_get_usage
        exit 1
    fi

    log_info "Getting workspace $workspace_name"
    # should fetch all workspaces and filter by name

    local response
    local status_code

    response=$(do_kong_request -m GET -p "$(get_workspace_path)")
    status_code=$?

    if [[ $status_code != 0 ]]; then
        log_error "Failed to get workspace $workspace_name"
        return 1
    fi

    response=$(echo "$response" | jq -r '.data[] | select(.name == "'"$workspace_name"'")')
    log_debug "$response"

    log_success "Workspace $workspace_name retrieved successfully"

    echo "$response"
}

workspace_usage() {
    log_info "Usage: workspace <command> [options]"
    log_info ""
    log_info "Commands:"
    log_info "  add [options]               Add a new workspace"
    log_info "  get [options]               Get a workspace"
    log_info "  -l, --list                  List all workspaces"
    log_info ""
    log_info "Options:"
    log_info "  -n, --name                  Name of the workspace"
}

workspace_add_usage() {
    log_info "Usage: workspace add [options]"
    log_info ""
    log_info "Options:"
    log_info "  -n, --name                  Name of the workspace"
}

workspace_get_usage() {
    log_info "Usage: workspace get [options]"
    log_info ""
    log_info "Options:"
    log_info "  -n, --name                  Name of the workspace"
}