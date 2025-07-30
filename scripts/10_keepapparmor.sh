#!/bin/bash

# SELinux is the new default but some people prefer AppArmor
# https://code.opensuse.org/leap/features/issue/182
# https://en.opensuse.org/SDB:AppArmor#Switching_from_SELinux_to_AppArmor_for_Leap_16.0_and_Tumbleweed

set -euo pipefail

log() {
    echo "[MIGRATION] $1"
}

error_exit() {
    echo "[MIGRATION][ERROR] $1" >&2
    exit 1
}

# Check if we have security=apparmor as boot param
if [[ "${1:-}" == "--check" ]]; then
    if ! /usr/sbin/update-bootloader --get-option security | grep apparmor &>/dev/null; then
        exit 0
    else
        exit 1
    fi
fi

log "Drop any SELinux boot options"
sudo update-bootloader --del-option "security=selinux"
sudo update-bootloader --del-option "enforcing=1"
sudo update-bootloader --del-option "selinux=1"
log "Adding AppArmor boot options"
sudo update-bootloader --add-option "security=apparmor"

if rpm -q patterns-base-apparmor &>/dev/null; then
    log "Package patterns-base-apparmor is already installed. Skipping."
    exit 0

else
    log "Installing packages: patterns-base-apparmor"
    if sudo zypper --non-interactive install --force-resolution patterns-base-apparmor; then
        log "Installation completed successfully."
    else
        error_exit "Package installation failed. Please check zypper logs or try again manually."
    fi
fi
