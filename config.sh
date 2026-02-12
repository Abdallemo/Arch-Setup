#!/usr/bin/env bash
source ./helper.sh

setup_config() {
    link_default() { link "$source_dir" "$target_dir"; }

    local folder_name=$1
    local action_func=${2:-link_default}
    local target_dir="$HOME/.config/$folder_name"
    local source_dir="$ROOT_DIR/dotfiles/$folder_name"

    if [ ! -d "$target_dir" ]; then
    log "Setting up $folder_name..."
    $action_func
    else
    log "$folder_name already exists."
    read -p "$(log "Do you want to replace it? (y/n) ")" -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Replacing existing $folder_name..."
        rm -rf "$target_dir"
        $action_func
    else
        log "Skipping $folder_name..."
    fi
    fi
}

link $ROOT_DIR/dotfiles/.zshrc ~/.zshrc
mkdir -p ~/.config/zsh_scripts
link $ROOT_DIR/dotfiles/common.sh ~/.config/zsh_scripts/common.sh
link $ROOT_DIR/helper.sh ~/.config/zsh_scripts/helper.sh

source $HOME/.zshrc

setup_nvim_repo() {
  git clone https://github.com/Abdallemo/neovim-setup.git "$HOME/.config/nvim"
}

setup_config "kitty"
setup_config "MangoHud"
setup_config "nvim" setup_nvim_repo


git config --global user.name >/dev/null || \
  safe_run git config --global user.name "Abdallemo"

git config --global user.email >/dev/null || \
  safe_run git config --global user.email "learn3038it@gmail.com"
