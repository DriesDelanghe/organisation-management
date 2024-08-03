#!/bin/bash

generate_password() {
    local db_password
    db_password="$(openssl rand -base64 25)"
    echo "$db_password"
}