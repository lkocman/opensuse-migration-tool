#!/bin/bash

# SELinux is the new default manual switch
# might be needed for people migrating from 15.X

# https://en.opensuse.org/SDB:AppArmor#Switching_from_SELinux_to_AppArmor_for_Leap_16.0_and_Tumbleweed

set -euo pipefail

log() {
    echo "[MIGRATION] $1"
}

error_exit() {
    echo "[MIGRATION][ERROR] $1" >&2
    exit 1
}

# Check if we have security=selinux as boot param
if [[ "${1:-}" == "--check" ]]; then
    if ! /usr/sbin/update-bootloader --get-option security | grep selinux &>/dev/null; then
        exit 0
    else
        exit 1
    fi
fi

log "Drop AppArmor boot options"
sudo update-bootloader --del-option "security=apparmor"

log "Add any SELinux boot options"
sudo update-bootloader --add-option "security=selinux"
sudo update-bootloader --add-option "enforcing=1"
sudo update-bootloader --add-option "selinux=1"

if rpm -q patterns-base-apparmor &>/dev/null; then
    log "Uninstalling packages: patterns-base-apparmor"
    if sudo zypper --non-interactive remove --force-resolution patterns-base-apparmor; then
        log "Uninstallation of AppArmor completed successfully."
    else
        error_exit "Package uninstallation failed. Please check zypper logs or try again manually."
    fi

else
    log "Installing packages: patterns-selinux selinux-policy-targeted-gaming"
    sudo zypper --non-interactive install -t pattern --force-resolution selinux
    sudo zypper --non-interactive install selinux-policy-targeted-gaming
fi
