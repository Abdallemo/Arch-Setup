export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"


plugins=(git fzf-tab)

source $ZSH/oh-my-zsh.sh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh


# Global Binaries
export PATH="$HOME/.local/bin:/usr/local/go/bin:/$HOME/go/bin:/usr/local/node/bin:/usr/lib/rstudio:/home/abdallemo/.config/herd-lite/bin:$PATH"
export PNPM_HOME="/home/abdallemo/.local/share/pnpm"
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
alias ls='(){ if command -v lsd >/dev/null 2>&1; then command lsd -hS --group-directories-first "$@"; else command ls -hS --group-directories-first "$@"; fi }'

alias grep='grep --color=auto'
alias p=pnpm
alias now='date +%Y%m%d_%H%M%S'
alias zsh_conf='zed $HOME/.config/zsh_scripts/common.sh'
#alias kreload="kbuildsycoca6 --noincremental"
alias reload="source ~/.zshrc"
alias htop='btop'
alias ipa='ip -br addr'
# Styles
zstyle ':fzf-tab:*' fzf-flags --preview-window=hidden --height=50%

CUSTOM_SCRIPTS="$HOME/.config/zsh_scripts/common.sh"
if [ -f "$CUSTOM_SCRIPTS" ]; then
    source "$CUSTOM_SCRIPTS"
fi

eval "$(direnv hook zsh)"
export FZF_CTRL_T_OPT="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

_fzf_comprun() {
local command=$1
shift
case “$command” in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \$' {}" "$@" ;;
    ssh)          fzf --preview 'dig {}' "$@" ;;
    *)            fzf --preview "--preview 'bat -n --color=always —-line-range :500 {}'" "$@" ;;
esac
}
export HSA_OVERRIDE_GFX_VERSION=10.3.0
export UV_CACHE_DIR="/games/uv-cache"


# Added by Antigravity CLI installer
export PATH="/home/abdallemo/.local/bin:$PATH"
