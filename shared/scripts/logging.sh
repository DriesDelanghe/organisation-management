#!/bin/bash

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