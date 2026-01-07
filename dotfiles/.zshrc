export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"


plugins=(git fzf-tab)

source $ZSH/oh-my-zsh.sh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh


# Global Binaries
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:/usr/local/node/bin"
export PNPM_HOME="/home/abdallemo/.local/share/pnpm"
export PATH="/home/abdallemo/.config/herd-lite/bin:$PATH"
export PHP_INI_SCAN_DIR="/home/abdallemo/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
export FNM_PATH="/home/abdallemo/.local/share/fnm"
export GTK_USE_PORTAL=1

if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env --shell zsh`"
fi

case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Aliases
alias ls='lsd -hS --group-directories-first'
alias grep='grep --color=auto'
alias p=pnpm

# Styles
zstyle ':fzf-tab:*' fzf-flags --preview-window=hidden --height=50%

CUSTOM_SCRIPTS="$HOME/.config/zsh_scripts/common.sh"
if [ -f "$CUSTOM_SCRIPTS" ]; then
    source "$CUSTOM_SCRIPTS"
fi
