#! /bin/bash

DEBUG=true

main () {
    setup_prerequisites
}

setup_prerequisites() {
    log_info "Searching system for k3s..."
    log_debug "which k3s"
    which k3s
    k3s_exists=$?
    log_debug "k3s_exists=$k3s_exists"

    # Install k3s if it does not exist
    if [ $k3s_exists -eq 1 ]; then
        log_info "k3s not found on system, running install..."
        log_debug "curl -sfL https://get.k3s.io | sh -s - --no-deploy traefik --write-kubeconfig-mode 644"
        curl -sfL https://get.k3s.io | sh -s - --no-deploy traefik --write-kubeconfig-mode 644 || {
            log_error "Failed to install k3s."
            exit 1
        }
        log_success "k3s successfully installed."
    else
        log_success "k3s was detected on the system, skipping install."
    fi
}

log_error() {
    printf '\033[31;1m%b%s\033[m\n' "$@" >&2
}

log_warn() {
    printf '\033[33;1m%b%s\033[m\n' "$@" >&2
}

log_info() {
    printf '\033[34;1m%b%s\033[m\n' "$@" >&2
}

log_success() {
    printf '\033[32;1m%b%s\033[m\n' "$@" >&2
}

log_debug() {
    if $DEBUG; then
        printf '\033[35;1m%b%s\033[m\n' "$@" >&2
    fi
}


main "$@"