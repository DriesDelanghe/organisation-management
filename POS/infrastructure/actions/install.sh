#! /bin/bash

DEBUG=false
use_lightweight_k8s=false

main () {
    resolve_parameters "$@"
    setup_prerequisites
}

resolve_parameters() {
    # read arguments
    while [ "$1" != "" ]; do
        case $1 in
            --debug )
                DEBUG=true
                ;;
            -l | --lightweight )
                use_lightweight_k8s=true
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

setup_prerequisites() {
    log_info "setting up kubernetes"
    log_info "#use_lightweight_k8s=$use_lightweight_k8s"
    if [[ $use_lightweight_k8s == true ]]; then
        install_k3s
    else
        install_k8s
    fi
}

install_k3s() {
    log_info "Searching system for k3s..."
    which k3s
    k3s_exists=$?

    # Install k3s if it does not exist
    if [ $k3s_exists -eq 1 ]; then
        log_info "k3s not found on system, running install..."
        curl -sfL https://get.k3s.io | sh -s - --no-deploy traefik --write-kubeconfig-mode 644 || {
            log_error "Failed to install k3s."
            exit 1
        }
        log_success "k3s successfully installed."
    else
        log_success "k3s was detected on the system, skipping install."
    fi
}

install_k8s() {
    log_info "Searching system for k8s..."
    which kubectl
    kubectl_exists=$?
    log_debug "kubectl_exists=$kubectl_exists"

    # Install k8s if it does not exist
    if [ $kubectl_exists -eq 1 ]; then
        log_info "k8s not found on system, running install..."
        log_info "resolving cpu architecture"
        cpu_arch=$(uname -m)
        log_info "downloading kubectl"
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$cpu_arch/kubectl"

        log_info "downloading kubectl sha256"
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$cpu_arch/kubectl.sha256"

        log_info "verifying kubectl sha256"
        echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check || {
            log_error "Failed to verify kubectl sha256."
            exit 1
        }

        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

        log_success "kubectl successfully installed."

    else
        log_success "k8s was detected on the system, skipping install."
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