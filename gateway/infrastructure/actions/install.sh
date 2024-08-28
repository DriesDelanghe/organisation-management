#! /bin/bash

# Global environments
DEBUG=false

gateway_compose_file="../docker/gateway.compose.yaml"
gateway_postgresql_secret_file="../docker/secrets/GATEWAY_POSTGRES_PASSWORD"
authentication_compose_file="../docker/keycloak.compose.yaml"
authentication_postgresql_secret_file="../docker/secrets/AUTH_POSTGRES_PASSWORD"

kong_scripts_output_dir="../../../shared/scripts/kong/output"
kong_api_config_file="$kong_scripts_output_dir/kong-config.json"

keycloak_output_dir="../../../shared/scripts/keycloak/output"
keycloak_config_file="$keycloak_output_dir/keycloak-config.json"

authentication_dump_file="./output/authentication-dump-$(date +%Y-%m-%d-%H-%M-%S).sql"


main() {
    resolve_parameters "$@"
    setup
    create_docker_network

    check_for_gateway_instance
    create_postgresql_password
    store_password
    deploy_gateway_compose
    wait_for_kong_response
    initialize_kong_variables
    set_kong_ratelimit
    set_default_proxy_cache

    check_for_authentication_instance
    generate_authentication_secrets
    store_authentication_secrets
    deploy_authentication_compose
    wait_for_auth_response
    restore_authentication_data

    access_token=$(get_token --realm "master" --username "keycloak" --password "$authentication_admin_password")
    log_info "Access token: $access_token"
}

resolve_parameters() {
    # read arguments
    while [ "$1" != "" ]; do
        case $1 in
            --debug )
                DEBUG=true
                ;;
            -h | --help )
                usage
                exit
                ;;
            * )
                usage
                exit 1
        esac
        shift
    done
}

usage() {
    log_info "Summary:"
    log_info "  This script is used to setup the basic gateway infrastructure. "
    log_info ""
    log_info "Usage: $0 [options]"
    log_info ""
    log_info "Options:"
    log_info "  --debug       Enable debug mode"
    log_info "  -h, --help    Show this help message and exit"
}

setup() {
    cd "$(dirname "$0")" || exit

    source "../../../shared/scripts/logging.sh"
    log_debug "Current working directory: $(pwd)"
    log_debug "Logging script loaded"

    log_debug "Loading password generator script..."
    source "../../../shared/scripts/password-generator.sh"
    log_debug "Password generator script loaded"

    log_debug "Loading kong helper methods"
    source "../../../shared/scripts/kong/kong.sh"
    log_debug "Kong helper methods loaded"

    log_debug "Loading keycloak helper methods"
    source "../../../shared/scripts/keycloak/keycloak.sh"
    log_debug "Keycloak helper methods loaded"
}

create_postgresql_password() {
    log_info "Creating PostgreSQL password..."
    kong_db_password="$(generate_password)"
    log_success "PostgreSQL password created."
}

store_password() {
    log_info "Storing PostgreSQL password..."

    # make ../docker/secrets directory if it does not exist
    mkdir -p ../docker/secrets

    echo "$kong_db_password" > "$gateway_postgresql_secret_file"
    log_success "PostgreSQL password stored."
}

create_docker_network() {
    log_info "Creating docker network..."
    docker network create gateway || true
    log_success "Docker network created."
}

check_for_gateway_instance() {
    log_info "Checking if kaleido-gateway is already running..."

    docker_kaleido_gateway=$(docker compose ls | grep "kaleido-gateway")
    log_debug "docker_kaleido_gateway=$docker_kaleido_gateway"

    if [[ -n $docker_kaleido_gateway ]]; then
        log_info "Kaleido-gateway is already running. Stopping it gracefully..."
        docker compose -f "$gateway_compose_file" down
        # delete volumes
        while docker compose ps | grep -q "kaleido-gateway"; do
            sleep 1
        done
        log_success "Kaleido-gateway stopped."
        
        log_info "deleting volumes..."
        docker volume rm gateway_postgres_data
        log_success "Kaleido-gateway stopped and volumes removed."

        log_info "Checking for kong config file..."
        if [[ -f "$kong_api_config_file" ]]; then
            log_info "Kong config file found, removing outdated kong config file..."
            rm "$kong_api_config_file"
            log_success "kong config file removed."
        else 
            log_info "no kong config file found."
        fi
    else
        log_info "no instance of kaleido-gateway found."
    fi
}

deploy_gateway_compose() {
    log_info "Deploying gateway compose..."
    docker compose -f "$gateway_compose_file" up -d
    log_success "Gateway compose deployed."
}

wait_for_kong_response() {
    log_info "Waiting for Kong response..."
    while true; do
        curl -s -o /dev/null http://localhost:8001 && break
        sleep 1
    done
    log_success "Kong is up and running."
}

initialize_kong_variables() {

    # Output files
    kong_output_dir="./output"
    mkdir -p "$kong_output_dir"

    # variables
    kong_max_requests_per_minute=60
    kong_cache_ttl=30
}

set_kong_ratelimit() {
    log_info "Setting Kong rate limit..."
    
    kong_rate_limiting_plugin_config=$(kong plugin add -n rate-limiting \
        --data "config.minute=$kong_max_requests_per_minute" \
        --data "config.policy=local")
    # $kong_rate_limiting_plugin_config > "$kong_output_ratelimit_config_file"

    log_success "Kong rate limit set to $kong_max_requests_per_minute request per minute."
}

set_default_proxy_cache() {
    log_info "Setting default proxy cache..."
    kong_cache_plugin_config=$(kong plugin add -n proxy-cache  \
        --data "config.request_method=GET" \
        --data "config.response_code=200" \
        --data "config.content_type=application/json;charset=utf-8" \
        --data "config.cache_ttl=$kong_cache_ttl" \
        --data "config.strategy=memory")
    # $kong_cache_plugin_config > "$kong_output_cache_config_file"

    log_success "Default proxy cache set wiith a ttl of $kong_cache_ttl."
}

check_for_authentication_instance() {
    log_info "Checking if kaleido-authentication is already running..."

    docker_kaleido_authentication=$(docker compose ls | grep "kaleido-authentication")
    log_debug "docker_kaleido_authentication=$docker_kaleido_authentication"
    if [[ -n $docker_kaleido_authentication ]]; then
        log_info "Kaleido-authentication is already running. "
        log_info "dumping current data to prevent data loss"
        docker compose -f "$authentication_compose_file" exec auth-database pg_dumpall -a -U keycloak > "$authentication_dump_file"
        log_info "Stopping it gracefully..."
        docker compose -f "$authentication_compose_file" down
        # delete volumes
        while docker compose ps | grep -q "kaleido-authentication"; do
            sleep 1
        done
        log_info "deleting volumes..."
        docker volume rm authentication_postgres_data
        log_success "Volumes removed."
        log_info "Checking for keycloak config file..."
        if [[ -f "$keycloak_config_file" ]]; then
            log_info "Keycloak config file found, removing outdated keycloak config file..."
            rm "$keycloak_config_file"
            log_success "Keycloak config file removed."
        else 
            log_info "no keycloak config file found."
        fi

        log_success "Kaleido-authentication stopped and volumes removed."

    else
        log_info "no instance of kaleido-authentication found."
    fi
}


generate_authentication_secrets() {
    log_info "Generating authentication secrets..."
    authentication_db_password="$(generate_password)"
    authentication_admin_password="$(generate_password)"
    log_success "Authentication secrets generated."
}

store_authentication_secrets() {

    log_info "Storing PostgreSQL password..."

    # make ../docker/secrets directory if it does not exist
    mkdir -p ../docker/secrets

    echo "$authentication_db_password" > "$authentication_postgresql_secret_file"
    log_success "PostgreSQL password stored."

    log_info "Storing keycloak admin access configuration..."

    mkdir -p "$keycloak_output_dir"
    keycloak_config=$(jq -n \
        --arg admin_password "$authentication_admin_password" \
        --arg admin_username "keycloak" \
        --arg url "http://localhost:8080" \
        '{url: $url, credentials: {username: $admin_username, password: $admin_password}}')
    log_debug "keycloak_config=$keycloak_config"
    echo "$keycloak_config" > "$keycloak_config_file"
    log_success "Keycloak admin access configuration stored."
}

deploy_authentication_compose() {
    echo """
    KEYCLOAK_ADMIN_PASSWORD=$authentication_admin_password
    POSTGRES_PASSWORD=$authentication_db_password
    POSTGRES_USER=keycloak
    POSTGRES_DB=keycloak
    """ > ../docker/secrets/.env

    log_info "Deploying authentication compose..."
    docker compose  -f "$authentication_compose_file" --env-file "../docker/secrets/.env" up -d --remove-orphans --force-recreate 
    log_success "Authentication compose deployed."
}

wait_for_auth_response() {
    log_info "Waiting for keycloak response..."
    while true; do
        curl -s -o /dev/null http://localhost:8080 && break
        sleep 1
    done
    log_success "Authentication is up and running."
    log_info "keycloak is now available at http://localhost:8080"
}

restore_authentication_data() {
    log_info "Restoring authentication data..."
    # only do this if there is a dump file
    if [[ ! -f "$authentication_dump_file" ]]; then
        log_info "No authentication data dump found. Skipping restoration."
        return
    fi
    cat "$authentication_dump_file" | docker compose -f "$authentication_compose_file" exec -tTd auth-database psql -U keycloak || {
        log_error "Failed to restore authentication data."
        exit 1
    }
    log_success "Authentication data restored."

    log_info "Cleaning up dump file..."
    rm "$authentication_dump_file"
    log_success "Dump file cleaned up."
}


main "$@"