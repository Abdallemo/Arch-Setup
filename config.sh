#!/usr/bin/env bash
source ./helper.sh

link() {
  src="$1"
  dst="$2"
  mkdir -p "$(dirname "$dst")"
  ln -sf "$src" "$dst"
  log "Linked $dst → $src"
}


link $ROOT_DIR/dotfiles/.zshrc ~/.zshrc


mkdir -p ~/.config/zsh_scripts
link $ROOT_DIR/dotfiles/common.sh ~/.config/zsh_scripts/common.sh

if [ ! -d ~/.config/nvim ]; then
  log "Cloning Neovim config..."
  safe_run git clone https://github.com/Abdallemo/neovim-setup.git ~/.config/nvim
else
  log "Neovim config already exists"
fi


git config --global user.name >/dev/null || \
  safe_run git config --global user.name "Abdallemo"

git config --global user.email >/dev/null || \
  safe_run git config --global user.email "learn3038it@gmail.com"
