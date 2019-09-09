#!/bin/bash

# Bootstraps environment I use on daily basis
# Installs all required software and symlinks config files from
# repository to the system

# Exit on error and print all commands
set -ex

# Get this script's directory
readonly DOT_SRC=$(cd "$(dirname "$0")"; pwd)


function create_dirs() {
    echo "Create dirs ..."
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/share"
    mkdir -p "$HOME/.local/bin"
}


function install_packages() {
    # Update system
    echo "Update packages ..."
    sudo dnf upgrade -y

    # Packages
    sudo dnf install -y \
        bzip2-devel \
        curl \
        cmake \
        doxygen \
        gcc \
        gcc-c++ \
        openssl-devel \
        pcre-devel \
        readline-devel \
        sqlite-devel \
        util-linux-user \
        wget \
        zlib-devel \
	gnome-tweak-tool

    # Code editing packages
    echo "Install software for development ..."
    sudo dnf install -y \
        ctags \
        git \
        make \

    # Editorconfig core
    cwd=$(pwd)
    cd /tmp
    git clone https://github.com/editorconfig/editorconfig-core-c.git
    cd editorconfig-core-c
    cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr . && make && sudo make install
    cd /tmp && rm -rf editorconfig-core-c
    cd "$cwd"
    unset cwd

    # Shell
    echo "Install shell tools ..."
    sudo dnf install -y \
        tmux \
        zsh
}


function install_pyenv() {
    echo "Install pyenv ..."
    local pyenv_dir="$HOME/.pyenv"
    local plugin_dir="${pyenv_dir}/plugins"
    local pyenv_repo='git://github.com/pyenv/pyenv.git'
    local pyenv_virtualenv_repo='git://github.com/pyenv/pyenv-virtualenv.git'
    local pyenv_update_repo='git://github.com/pyenv/pyenv-update.git'

    if [ -d "${pyenv_dir}" ]; then
        rm -rf "${pyenv_dir}"
    fi

    # Clone everything
    git clone "${pyenv_repo}" "${pyenv_dir}"
    git clone "${pyenv_virtualenv_repo}" "${plugin_dir}/pyenv-virtualenv"
    git clone "${pyenv_update_repo}" "${plugin_dir}/pyenv-update"

    # Initialize pyenv
    export PYENV_ROOT="${pyenv_dir}"
    export PATH="${pyenv_dir}/bin:$PATH"
    eval "$(pyenv init -)"

    # Install python interpreters
    echo "Install python interpreters ..."
    pyenv install 2.7.14
    pyenv install 3.6.6
}


function install_rustup() {
    echo "Install rustup ..."
    curl https://sh.rustup.rs -sSf | sh
}

function install_elm() {
    echo "Install elm ..."
    dnf install node npm
    wget "https://github.com/elm/compiler/releases/download/0.19.0/binaries-for-linux.tar.gz"
    tar xzf binaries-for-linux.tar.gz
    mv elm /usr/local/bin/
}


function install_tmux() {
    echo "Install tmux configuration ..."
    local tpm_repo='git://github.com/tmux-plugins/tpm.git'
    local tpm_dir="$HOME/.tmux/plugins/tpm"

    if [ -e "$HOME/.tmux.conf" -o -h "$HOME/.tmux.conf" ]; then
        rm "$HOME/.tmux.conf"
    fi
    if [ -e "${tpm_dir}" -o -h "${tpm_dir}" ]; then
        rm -rf "${tpm_dir}"
    fi

    git clone "${tpm_repo}" "${tpm_dir}"
    ln -s "${DOT_SRC}/tmux/.tmux.conf" "$HOME/.tmux.conf"

    local readonly session_name="dotfiles-$(date +%s)"
    tmux new-session -s "${session_name}" "${tpm_dir}/bindings/install_plugins"
}


function install_oh_my_tmux() {
   echo "Install .tmux aka Oh My Tmux! ..."
   export $TERM="xterm-256color"
   export $EDITOR="vim"
   cd
   git clone https://github.com/gpakosz/.tmux.git
   ln -s -f .tmux/.tmux.conf
   cp .tmux/.tmux.conf.local .
}


function install_teamocil() {
   echo "Install teamocil ..."
   gem install teamocil
   mkdir ~/.teamocil
}


function install_zsh() {
    echo "Install zsh configuration ..."
    local ohmyzsh_dir="$HOME/.oh-my-zsh"
    local zshrc="$HOME/.zshrc"
    local ohmyzsh_custom="${ohmyzsh_dir}/custom"
    local ohmyzsh_repo="git://github.com/robbyrussell/oh-my-zsh.git"
    local spaceship_repo="git://github.com/denysdovhan/spaceship-prompt.git"

    for file in "${ohmyzsh_dir}" "${zshrc}"; do
        if [ -e "${file}" -o -h "${file}" ]; then
            rm -rf "${file}"
        fi
    done

    # Oh My Zsh
    echo "Install Oh My Zsh ..."
    git clone --depth=1 "${ohmyzsh_repo}" "${ohmyzsh_dir}"

    # Spaceship theme
    echo "Install spaceship theme ..."
    mkdir -p "${ohmyzsh_custom}/themes"
    git clone "${spaceship_repo}" "${ohmyzsh_custom}/themes/spaceship-prompt"
    ln -s \
        "${ohmyzsh_custom}/themes/spaceship-prompt/spaceship.zsh-theme" \
        "${ohmyzsh_custom}/themes/spaceship.zsh-theme"

    # Symlink aliases
    echo "Install aliases ..."
    local readonly ohmyzsh_aliases="${ohmyzsh_custom}/aliases.zsh"
    if [ -e "${ohmyzsh_aliases}" -o -h "${ohmyzsh_aliases}" ]; then
        rm -r "${ohmyzsh_custom}/aliases.zsh"
    fi
    ln -s "${DOT_SRC}/zsh/aliases.zsh" "${ohmyzsh_aliases}"

    # ~/.zshrc
    echo "Symlink .zshrc ..."
    ln -s "${DOT_SRC}/zsh/.zshrc" "${zshrc}"

    echo "Change user shell ..."
    chsh -s /bin/zsh || echo 'Shell was not changed'
}

function install_snap_and_vscode() {
    echo "Install snap"
    sudo dnf install snapd

    echo "Enable --classic support"
    sudo ln -s /var/lib/snapd/snap /snap

    echo "Install vscode via snap"
    sudo snap install --classic code # or code-insiders  
}


function main() {
    create_dirs
    install_packages

    install_pyenv
    install_rustup
    install_elm

    install_tmux
    install_oh_my_tmux
    install_teamocil
    install_zsh
    install_snap_and_vscode
}

# Run everything
main
