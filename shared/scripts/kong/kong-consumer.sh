#!/bin/bash

consumer() {

    if [[ "$1" == "" ]]; then
        consumer_usage
        exit 1
    fi

    local result

    case $1 in
        create )
            shift
            result=$(consumer_create "$@")
            ;;
        get )
            shift
            result=$(consumer_get "$@")
            ;;
        key )
            shift
            result=$(consumer_key "$@")
            ;;
        group )
            shift
            result=$(consumer_group "$@")
            ;;
        acl )
            shift
            result=$(consumer_acl "$@")
            ;;
        -l | --list )
            result=$(consumer_list "$@")
            ;;
        -h | --help )
            consumer_usage
            exit 0
            ;;
        * )
            usage
            exit 1
    esac

    echo "$result"
}

consumer_list() {

    local workspace_name

    while [[ "$1" != "" ]]; do
        case $1 in
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            * )
                consumer_list_usage
                exit 1
        esac
        shift
    done
    

    log_info "Listing all consumers"
    local response
    local status_code
    local path

    if [[ "$workspace_name" == "" ]]; then
        path=$(get_consumer_path)
    else
        path=$(get_workspace_consumer_path "$workspace_name")
    fi

    response=$(do_kong_request -m GET -p "$path")
    status_code=$?

    if [[ $status_code -ne 0 ]]; then
        log_error "Failed to list consumers"
        exit 1
    fi

    log_success "Consumers listed successfully"

    response=$(echo "$response" | jq -r '.data[]')
    log_debug "$response"

    echo "$response"
}

consumer_create() {
    if [[ "$1" == "" ]]; then
        consumer_create_usage
        exit 1
    fi

    local workspace_name
    local consumer_username
    local consumer_id
    local tags
    tags=()

    while [[ "$1" != "" ]]; do
        case $1 in
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            -n | --name )
                shift
                consumer_username=$1
                ;;
            -i | --id )
                shift
                consumer_id=$1
                ;;
            -t | --tags )
                shift
                tags+=("$1")
                ;;
            * )
                consumer_create_usage
                exit 1
        esac
        shift
    done

    if [[ "$consumer_username" == "" ]]; then
        log_error "Consumer username is required"
        log_info ""
        consumer_create_usage
        exit 1
    fi

    if [[ "$consumer_id" == "" ]]; then
        # if cusnumer_id is not provided, this should be equal to the username in lowercase and with spaces as underscores
        consumer_id=$(echo "$consumer_username" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    fi

    log_info "Creating consumer $consumer_username"

    local path
    local response
    local status_code

    if [[ "$workspace_name" == "" ]]; then
        path=$(get_consumer_path)
    else
        path=$(get_workspace_consumer_path "$workspace_name")
    fi

    response=$(do_kong_request -m POST -p "$path" -d "username=$consumer_username" -d "custom_id=$consumer_id" -d "tags[]=$(IFS=,; echo "${tags[*]}")")
    status_code=$?

    if [[ $status_code != 0 ]]; then
        log_error "Failed to create consumer $consumer_username"
        exit 1
    fi

    log_success "Consumer $consumer_username created successfully"

    response=$(echo "$response" | jq -r '.')
    log_debug "$response"

    echo "$response"
}

consumer_get() {
    if [[ "$1" == "" ]]; then
        consumer_get_usage
        exit 1
    fi

    local workspace_name
    local consumer_id
    local consumer_username

    while [[ "$1" != "" ]]; do
        case $1 in
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            -n | --name )
                shift
                consumer_username=$1
                ;;
            -i | --id )
                shift
                consumer_id=$1
                ;;
            * )
                consumer_get_usage
                exit 1
        esac
        shift
    done

    if [[ "$consumer_id" == "" && "$consumer_username" == "" ]]; then
        log_error "Consumer name or id is required"
        log_info ""
        consumer_get_usage
        exit 1
    fi

    if [[ "$consumer_id" != "" && "$consumer_username" != "" ]]; then
        log_error "Only one of consumer name or id can be provided"
        log_info ""
        consumer_get_usage
        exit 1
    fi

    log_info "Getting consumer $consumer_id"
    local path
    local response
    local status_code

    if [[ "$workspace_name" == "" ]]; then
        path=$(get_consumer_path "$consumer_id")
    else
        path=$(get_workspace_consumer_path "$workspace_name" "$consumer_id")
    fi

    response=$(do_kong_request -m GET -p "$path")
    status_code=$?

    if [[ $status_code != 0 ]]; then
        if [[ $consumer_id == "" ]]; then
            log_error "Failed to get consumer $consumer_username"
        else
            log_error "Failed to get consumer $consumer_id"
        fi
        exit 1
    fi

    if [[ "$consumer_id" == "" ]]; then
        response=$(echo "$response" | jq -r '.data[] | select(.username == "'"$consumer_username"'")')
    fi



    log_success "Consumer $consumer_id retrieved successfully"

    response=$(echo "$response" | jq -r '.')
    log_debug "$response"

    echo "$response"
}

consumer_key() {
    local result

    case $1 in
        get )
            shift
            result=$(consumer_key_get "$@")
            ;;
        create )
            shift
            result=$(consumer_key_create "$@")
            ;;
        -h | --help )
            consumer_key_usage
            exit 0
            ;;
        * )
            consumer_key_usage
            exit 1
    esac   

    echo "$result"
}

consumer_key_get() {
    if [[ "$1" == "" ]]; then
        consumer_key_usage
        exit 1
    fi

    local workspace_name
    local consumer_id
    local consumer_username

    while [[ "$1" != "" ]]; do
        case $1 in
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            -n | --name )
                shift
                consumer_username=$1
                ;;
            -i | --id )
                shift
                consumer_id=$1
                ;;
            * )
                consumer_key_usage
                exit 1
        esac
        shift
    done

    if [[ "$consumer_id" == "" && "$consumer_username" == "" ]]; then
        log_error "Consumer name or id is required"
        log_info ""
        consumer_key_usage
        exit 1
    fi

    if [[ "$consumer_id" != "" && "$consumer_username" != "" ]]; then
        log_error "Only one of consumer name or id can be provided"
        log_info ""
        consumer_key_usage
        exit 1
    fi

    if [[ $consumer_id == "" ]]; then
        consumer_id=$(consumer_get -w "$workspace_name" -n "$consumer_username" | jq -r '.id')
    fi

    log_info "Getting consumer key $consumer_id"
    local path
    local response
    local status_code

    if [[ "$workspace_name" == "" ]]; then
        path=$(get_consumer_key_path "$consumer_id")
    else
        path=$(get_workspace_consumer_key_path "$workspace_name" "$consumer_id")
    fi

    response=$(do_kong_request -m GET -p "$path")
    status_code=$?

    if [[ $(echo "$response" | jq -r '.key') == "" || $status_code != 0 ]]; then
        log_error "Failed to get consumer key $consumer_id"
        exit 1
    fi

    log_success "Consumer key for $consumer_id retrieved successfully"

    response=$(echo "$response" | jq -r '.')
    log_debug "$response"

    echo "$response"
}

consumer_key_create() {
    if [[ "$1" == "" ]]; then
        consumer_key_create_usage
        exit 1
    fi

    local workspace_name
    local consumer_id
    local consumer_username
    local tags
    tags=()

    while [[ "$1" != "" ]]; do
        case $1 in
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            -n | --name )
                shift
                consumer_username=$1
                ;;
            -i | --id )
                shift
                consumer_id=$1
                ;;
            -t | --tags )
                shift
                tags+=("$1")
                ;;
            * )
                consumer_key_create_usage
                exit 1
        esac
        shift
    done

    if [[ "$consumer_id" == "" && "$consumer_username" == "" ]]; then
        log_error "Consumer name or id is required"
        log_info ""
        consumer_key_create_usage
        exit 1
    fi

    if [[ "$consumer_id" != "" && "$consumer_username" != "" ]]; then
        log_error "Only one of consumer name or id can be provided"
        log_info ""
        consumer_key_create_usage
        exit 1
    fi

    if [[ $consumer_id == "" ]]; then
        consumer_id=$(consumer_get -w "$workspace_name" -n "$consumer_username" | jq -r '.id')
    fi

    log_info "Creating consumer key $consumer_id"
    local path
    local response
    local status_code

    if [[ "$workspace_name" == "" ]]; then
        path=$(get_consumer_key_path "$consumer_id")
    else
        path=$(get_workspace_consumer_key_path "$workspace_name" "$consumer_id")
    fi

    response=$(do_kong_request -m POST -p "$path" -d "tags[]=$(IFS=,; echo "${tags[*]}")")
    status_code=$?

    if [[ $status_code != 0 ]]; then
        log_error "Failed to create consumer key $consumer_id"
        exit 1
    fi

    log_success "Consumer key for $consumer_id created successfully"

    response=$(echo "$response" | jq -r '.')
    log_debug "$response"

    echo "$response"
}

consumer_group() {
    local result

    case $1 in
        create )
            shift
            result=$(consumer_group_create "$@")
            ;;
        get )
            shift
            result=$(consumer_group_get "$@")
            ;;
        add )
            shift
            result=$(consumer_group_add "$@")
            ;;
        -h | --help )
            consumer_group_usage
            exit 0
            ;;
        -l | --list )
            result=$(consumer_group_list "$@")
            ;;
        * )
            consumer_group_usage
            exit 1
    esac

    echo "$result"
}

consumer_group_create() {
    if [[ "$1" == "" ]]; then
        consumer_group_create_usage
        exit 1
    fi

    local workspace_name
    local group_name
    local tags
    tags=()

    while [[ "$1" != "" ]]; do
        case $1 in
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            -n | --name )
                shift
                group_name=$1
                ;;
            -t | --tags )
                shift
                tags+=("$1")
                ;;
            * )
                consumer_group_create_usage
                exit 1
        esac
        shift
    done

    if [[ "$group_name" == "" ]]; then
        log_error "Group name is required"
        log_info ""
        consumer_group_create_usage
        exit 1
    fi

    log_info "Creating consumer group $group_name"

    local path
    local response
    local status_code

    if [[ "$workspace_name" == "" ]]; then
        path=$(get_consumers_group_path)
    else
        path=$(get_workspace_consumers_group_path "$workspace_name")
    fi

    response=$(do_kong_request -m POST -p "$path" -d "name=$group_name" -d "tags[]=$(IFS=,; echo "${tags[*]}")")
    status_code=$?

    if [[ $status_code != 0 ]]; then
        log_error "Failed to create consumer group $group_name"
        exit 1
    fi

    log_success "Consumer group $group_name created successfully"

    response=$(echo "$response" | jq -r '.')
    log_debug "$response"

    echo "$response"

}

consumer_group_get() {
    if [[ "$1" == "" ]]; then
        consumer_group_get_usage
        exit 1
    fi

    local workspace_name
    local group_id
    local group_name

    while [[ "$1" != "" ]]; do
        case $1 in
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            -n | --name )
                shift
                group_name=$1
                ;;
            -i | --id )
                shift
                group_id=$1
                ;;
            * )
                consumer_group_get_usage
                exit 1
        esac
        shift
    done

    if [[ "$group_id" == "" && "$group_name" == "" ]]; then
        log_error "Group name or id is required"
        log_info ""
        consumer_group_get_usage
        exit 1
    fi

    if [[ "$group_id" != "" && "$group_name" != "" ]]; then
        log_error "Only one of group name or id can be provided"
        log_info ""
        consumer_group_get_usage
        exit 1
    fi

    log_info "Getting consumer group $group_id"
    local path
    local response
    local status_code

    if [[ "$workspace_name" == "" ]]; then
        path=$(get_consumers_group_path "$group_id")
    else
        path=$(get_workspace_consumers_group_path "$workspace_name" "$group_id")
    fi

    response=$(do_kong_request -m GET -p "$path")
    status_code=$?

    if [[ $status_code != 0 ]]; then
        if [[ "$group_id" == "" ]]; then
            log_error "Failed to get consumer group $group_name"
        else
            log_error "Failed to get consumer group $group_id"
        fi
        exit 1
    fi

    if [[ "$group_id" == "" ]]; then
        response=$(echo "$response" | jq -r '.data[] | select(.group == "'"$group_name"'")')
    fi

    log_success "Consumer group $group_id retrieved successfully"

    response=$(echo "$response" | jq -r '.')
    log_debug "$response"

    echo "$response"
}

consumer_group_list() {
    local workspace_name

    while [[ "$1" != "" ]]; do
        case $1 in
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            * )
                consumer_group_list_usage
                exit 1
        esac
        shift
    done

    log_info "Listing all consumer groups"
    local response
    local status_code
    local path

    if [[ "$workspace_name" == "" ]]; then
        path=$(get_consumers_group_path)
    else
        path=$(get_workspace_consumers_group_path "$workspace_name")
    fi

    response=$(do_kong_request -m GET -p "$path")
    status_code=$?

    if [[ $status_code -ne 0 ]]; then
        log_error "Failed to list consumer groups"
        exit 1
    fi

    log_success "Consumer groups listed successfully"

    response=$(echo "$response" | jq -r '.data[]')
    log_debug "$response"

    echo "$response"
}

consumer_group_add() {
    if [[ "$1" == "" ]]; then
        consumer_group_add_usage
        exit 1
    fi

    local workspace_name
    local group_name
    local consumer_username

    while [[ "$1" != "" ]]; do
        case $1 in
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            -g | --group )
                shift
                group_name=$1
                ;;
            -c | --consumer )
                shift
                consumer_username=$1
                ;;
            * )
                consumer_group_add_usage
                exit 1
        esac
        shift
    done

    if [[ "$group_name" == "" ]]; then
        log_error "Group name is required"
        log_info ""
        consumer_group_add_usage
        exit 1
    fi

    if [[ "$consumer_username" == "" ]]; then
        log_error "Consumer name is required"
        log_info ""
        consumer_group_add_usage
        exit 1
    fi

    if [[ "$workspace_name" == "" ]]; then
        consumer_id=$(consumer_get -n "$consumer_username" | jq -r '.id')
    else
        consumer_id=$(consumer_get -w "$workspace_name" -n "$consumer_username" | jq -r '.id')
    fi

    log_info "Adding consumer $consumer_id to group $group_name"

    local path
    local response
    local status_code

    if [[ "$workspace_name" == "" ]]; then
        path=$(get_consumers_group_path "$group_name")
    else
        path=$(get_workspace_consumers_group_path "$workspace_name" "$group_name")
    fi

    response=$(do_kong_request -m PATCH -p "$path" -d "consumer=$consumer_id")
    status_code=$?

    if [[ $status_code != 0 ]]; then
        log_error "Failed to add consumer $consumer_id to group $group_name"
        exit 1
    fi

    log_success "Consumer $consumer_id added to group $group_name successfully"

    response=$(echo "$response" | jq -r '.')
    log_debug "$response"

    echo "$response"
}

consumer_acl() {
    
    local workspace_name
    local consumer_username
    local group_name
    local tags
    tags=()

    while [[ "$1" != "" ]]; do
        case $1 in
            -w | --workspace )
                shift
                workspace_name=$1
                ;;
            -g | --group )
                shift
                group_name=$1
                ;;
            -c | --consumer )
                shift
                consumer_username=$1
                ;;
            -t | --tags )
                shift
                tags+=("$1")
                ;;
            * )
                consumer_acl_add_usage
                exit 1
        esac
        shift
    done

    if [[ "$group_name" == "" ]]; then
        log_error "Group name is required"
        log_info ""
        consumer_acl_add_usage
        exit 1
    fi

    if [[ "$consumer_username" == "" ]]; then
        log_error "Consumer name is required"
        log_info ""
        consumer_acl_add_usage
        exit 1
    fi

    local path
    local response
    local status_code

    if [[ "$workspace_name" == "" ]]; then
        path=$(get_consumers_acl_path "$consumer_username")
    else
        path=$(get_workspace_consumer_acl_path "$workspace_name" "$consumer_username")
    fi

    response=$(do_kong_request -m POST -p "$path" -d "group=$group_name" -d "tags[]=$(IFS=,; echo "${tags[*]}")")
    status_code=$?

    if [[ $status_code != 0 ]]; then
        log_error "Failed to add consumer $consumer_username to group $group_name"
        exit 1
    fi

    log_success "Consumer $consumer_username added to group $group_name successfully"

    response=$(echo "$response" | jq -r '.')
    log_debug "$response"

    echo "$response"
}

consumer_usage() {
    log_info "Usage: kong consumer <command> [options]"
    log_info "Commands:"
    log_info "  create [options]                create a consumer"
    log_info "  get [options]                   Get a consumer"
    log_info "  -l, --list                      List all consumers"
    log_info ""
    log_info "Options:"
    log_info "  -h, --help                      Display this help message"
}

consumer_create_usage() {
    log_info "Usage: kong consumer create [options]"
    log_info ""
    log_info "Options:"
    log_info "  -i, --id <id>                   Consumer id"
    log_info "  -n, --name <name>               Consumer name"
    log_info "  -t, --tags <tags>               Tags"
    log_info "  -w, --workspace <workspace>     Workspace name"
}

consumer_get_usage() {
    log_info "Usage: kong consumer get [options]"
    log_info "Get a consumer"
    log_info ""
    log_info "Options:"
    log_info "  -i, --id <id>                   Consumer id"
    log_info "  -n, --name <name>               Consumer name"
    log_info "  -w, --workspace <workspace>     Workspace name"
}

consumer_list_usage() {
    log_info "Usage: kong consumer -l [options]"
    log_info "List all consumers"
    log_info ""
    log_info "Options:"
    log_info "  -w, --workspace <workspace>     Workspace name"
}

consumer_key_usage() {
    log_info "Usage: kong consumer key <command> [options]"
    log_info "Commands:"
    log_info "  get [options]                   Get a consumer key"
    log_info "  create [options]                create a consumer key"
    log_info ""
    log_info "Options:"
    log_info "  -h, --help                      Display this help message"
}

consumer_key_get_usage() {
    log_info "Usage: kong consumer key get [options]"
    log_info "Get a consumer key"
    log_info ""
    log_info "Options:"
    log_info "  -i, --id <id>                   Consumer id"
    log_info "  -n, --name <name>               Consumer name"
    log_info "  -w, --workspace <workspace>     Workspace name"
}

consumer_key_create_usage() {
    log_info "Usage: kong consumer key create [options]"
    log_info ""
    log_info "Options:"
    log_info "  -i, --id <id>                   Consumer id"
    log_info "  -n, --name <name>               Consumer name"
    log_info "  -t, --tags <tags>               Tags"
    log_info "  -w, --workspace <workspace>     Workspace name"
}

consumer_group_usage() {
    log_info "Usage: kong consumer group <command> [options]"
    log_info "Commands:"
    log_info "  create [options]                create a consumer group"
    log_info "  get [options]                   Get a consumer group"
    log_info "  add [options]                   Add a consumer to a group"
    log_info "  -l, --list                      List all consumer groups"
    log_info ""
    log_info "Options:"
    log_info "  -h, --help                      Display this help message"
}

consumer_group_create_usage() {
    log_info "Usage: kong consumer group create [options]"
    log_info ""
    log_info "Options:"
    log_info "  -n, --name <name>               Group name"
    log_info "  -t, --tags <tags>               Tags"
    log_info "  -w, --workspace <workspace>     Workspace name"
}

consumer_group_get_usage() {
    log_info "Usage: kong consumer group get [options]"
    log_info "Get a consumer group"
    log_info ""
    log_info "Options:"
    log_info "  -i, --id <id>                   Group id"
    log_info "  -n, --name <name>               Group name"
    log_info "  -w, --workspace <workspace>     Workspace name"
}

consumer_group_list_usage() {
    log_info "Usage: kong consumer group -l [options]"
    log_info "List all consumer groups"
    log_info ""
    log_info "Options:"
    log_info "  -w, --workspace <workspace>     Workspace name"
}

consumer_group_add_usage() {
    log_info "Usage: kong consumer group add [options]"
    log_info ""
    log_info "Options:"
    log_info "  -g, --group <group>             Group name"
    log_info "  -c, --consumer <consumer>       Consumer name"
    log_info "  -w, --workspace <workspace>     Workspace name"
}

consumer_acl_add_usage() {
    log_info "Usage: kong consumer acl [options]"
    log_info ""
    log_info "Options:"
    log_info "  -g, --group <group>             Group name"
    log_info "  -c, --consumer <consumer>       Consumer name"
    log_info "  -t, --tags <tags>               Tags"
    log_info "  -w, --workspace <workspace>     Workspace name"
}