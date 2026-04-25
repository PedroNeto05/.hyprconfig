#!/bin/bash
set -e

export DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/modules/pre/01_dependencies.sh"
source "$SCRIPT_DIR/modules/pre/02_environment.sh"

install_pre_dependencies

setup_pre_environment
