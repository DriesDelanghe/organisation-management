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
    log_info "Listing all workspaces"
    response=$(curl -s --request GET \
        --url "$(get_workspace_url)" \
        --header "Content-Type: application/json" | jq -r '.')
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
    response=$(curl -s --request POST \
        --fail \
        --url "$(get_workspace_url)" \
        --data "name=$workspace_name" | jq -r '.')
    result_code=$?
    log_debug "$response"
    if [[ $(echo "$response" | jq -r '.id') == "" || result_code -ne 0 ]]; then
        log_error "Failed to create workspace $workspace_name"
        return 1
    fi

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
    response=$(curl -s --request GET \
        --url "$(get_workspace_url)" \
        --header "Content-Type: application/json" | jq -r '.data[] | select(.name == "'"$workspace_name"'")')
    result_code=$?

    log_debug "$response"
    if [[ $(echo "$response" | jq -r '.id') == "null" || result_code -ne 0 ]]; then
        log_error "Failed to get workspace $workspace_name"
        return 1
    fi

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