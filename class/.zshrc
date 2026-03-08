# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set zinit and plugins directory
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

zinit light zsh-users/zsh-completions

# Auto notify
zinit light MichaelAquilina/zsh-auto-notify
AUTO_NOTIFY_THRESHOLD=1000

# snippets
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

# zsh plugins (must be loaded after compinit)
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-history-substring-search

zinit ice wait lucid
zinit light MichaelAquilina/zsh-you-should-use

zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting

zinit cdreplay -q

# Keybindings
bindkey -e
bindkey '^p' history-substring-search-up
bindkey '^n' history-substring-search-down
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[w' kill-region

# History
HISTSIZE=100000
HISTFILE=~/.zsh_history
SAVEHIST=100000
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Command correction
setopt correct

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --color=always $realpath'
zstyle ':fzf-tab:complete:(bat|cat|nvim|vim):*' fzf-preview 'bat --color=always --style=numbers $realpath || cat $realpath'
zstyle ':fzf-tab:complete:-command-:*' fzf-preview 'echo $word'

# Aliases
alias ls='eza --icons=always --color=always'
alias cat='bat --style=plain --paging=never'
alias zi='zoxide query -i'
alias vim='nvim'
alias c='clear'

# Git Aliases (Replacing OMZ git plugin)
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gcmsg='git commit -m'
alias gco='git checkout'
alias gl='git pull'
alias gp='git push'
alias gst='git status'
alias gd='git diff'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

#-----------------------------------------------------------------------
#                            ENVIRONMENT
#-----------------------------------------------------------------------

# Set the default editor for command-line tools
export EDITOR=nano
export VISUAL=nano

#-----------------------------------------------------------------------
#                                PATH
#-----------------------------------------------------------------------

typeset -U path # Keep duplicates out
path=(
  $HOME/.local/bin
  $path
)
export PATH



#-----------------------------------------------------------------------
#                           USER FUNCTIONS
#-----------------------------------------------------------------------
ex() {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

#-----------------------------------------------------------------------
#                           ADVANCED WIDGETS
#-----------------------------------------------------------------------

# 0. Sudo toggle: Re-run the current or previous command as root (Double-Escape)
sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    elif [[ $BUFFER == $EDITOR\ * ]]; then
        LBUFFER="${LBUFFER#$EDITOR }"
        LBUFFER="sudoedit $LBUFFER"
    elif [[ $BUFFER == sudoedit\ * ]]; then
        LBUFFER="${LBUFFER#sudoedit }"
        LBUFFER="$EDITOR $LBUFFER"
    else
        LBUFFER="sudo $LBUFFER"
    fi
}
zle -N sudo-command-line
bindkey '\e\e' sudo-command-line

# 1. Edit current command string in Nano (Ctrl+X Ctrl+E)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

#-----------------------------------------------------------------------
#                      SUFFIX AND GLOBAL ALIASES
#-----------------------------------------------------------------------

# Suffix Aliases (Open by just typing the filename)
alias -s md=bat
alias -s txt=bat
alias -s log=bat
alias -s json=bat
alias -s yaml=bat
alias -s toml=bat

# Global Aliases (Use anywhere in command, usually at the end)
alias -g NE='2>/dev/null'        # Drop standard error
alias -g NO='>/dev/null'         # Drop standard output
alias -g NUL='>/dev/null 2>&1'   # Drop both
alias -g G='| rg'                # Quick ripgrep

