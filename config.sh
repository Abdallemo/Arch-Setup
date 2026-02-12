#!/usr/bin/env bash
source ./helper.sh

link $ROOT_DIR/dotfiles/.zshrc ~/.zshrc


mkdir -p ~/.config/zsh_scripts

link $ROOT_DIR/dotfiles/common.sh ~/.config/zsh_scripts/common.sh
link $ROOT_DIR/helper.sh ~/.config/zsh_scripts/helper.sh

if [ ! -d ~/.config/nvim ]; then
  log "Cloning Neovim config..."
  safe_run git clone https://github.com/Abdallemo/neovim-setup.git ~/.config/nvim
else
  log "Neovim config already exists"
fi

if [ ! -d ~/.config/kitty ]; then
  log "Copying Kitty config..."
  link $ROOT_DIR/dotfiles/kitty ~/.config/kitty
else
  log "Kitty config already exists."
  log "Do you want to replace it? (y/n) "
  read -n 1 -r

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Replacing existing config..."
    rm -rf ~/.config/kitty
    link $ROOT_DIR/dotfiles/kitty ~/.config/kitty
  else
    log "Skipping..."
  fi
fi


git config --global user.name >/dev/null || \
  safe_run git config --global user.name "Abdallemo"

git config --global user.email >/dev/null || \
  safe_run git config --global user.email "learn3038it@gmail.com"
