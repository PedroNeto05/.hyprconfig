#!/bin/bash
set -e

export DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/pre_packages.sh"
source "$SCRIPT_DIR/pre_setup.sh"

install_essentials

run_pre_setup
