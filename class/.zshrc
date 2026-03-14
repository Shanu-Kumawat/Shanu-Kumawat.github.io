# ========================================================================
#                    ZSH CONFIGURATION FILE
# ========================================================================
# This file configures your Zsh shell with plugins, aliases, and settings.
# Created for Arch Linux WSL Workshop - Modified for macOS compatibility
# ========================================================================

# ----------------------------------------------------------------------
# POWERLEVEL10K INSTANT PROMPT (Must be at the top)
# ----------------------------------------------------------------------
# This makes your shell load faster by pre-loading the prompt theme.
# Don't move this block - it needs to be near the top to work properly.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ----------------------------------------------------------------------
# ZINIT PLUGIN MANAGER SETUP
# ----------------------------------------------------------------------
# Zinit is a plugin manager for Zsh - it downloads and manages plugins.
# This section sets up Zinit and prepares it to load plugins.
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# If Zinit isn't installed, download it from GitHub
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Load Zinit so we can use it to manage other plugins
source "${ZINIT_HOME}/zinit.zsh"

# ----------------------------------------------------------------------
# THEME: POWERLEVEL10K
# ----------------------------------------------------------------------
# This sets up the nice looking prompt you see in the terminal.
# Run 'p10k configure' to customize it, or edit ~/.p10k.zsh
zinit ice depth=1; zinit light romkatv/powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ----------------------------------------------------------------------
# COMPLETIONS (Tab completion suggestions)
# ----------------------------------------------------------------------
# These plugins provide auto-complete suggestions as you type.
zinit light zsh-users/zsh-completions   # Extra completion for many commands

# ----------------------------------------------------------------------
# NOTIFICATIONS (Alert when long commands finish)
# ----------------------------------------------------------------------
# Notifies you when a command takes longer than 1000 seconds (set to 0 to disable)
zinit light MichaelAquilina/zsh-auto-notify
AUTO_NOTIFY_THRESHOLD=1000

# ----------------------------------------------------------------------
# SNIPPETS (Pre-made configurations for tools)
# ----------------------------------------------------------------------
# These load ready-made setups for various tools.
# aws - Auto-complete for AWS CLI
# kubectl - Kubernetes command completion
# kubectx - Kubernetes context switching
# command-not-found - Suggests packages when commands aren't found
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completion system (required for tab-completion to work)
autoload -Uz compinit && compinit

# ----------------------------------------------------------------------
# PLUGINS (Must load AFTER compinit)
# ----------------------------------------------------------------------
# fzf-tab: Makes tab-completion show a searchable menu (fzf)
zinit light Aloxaf/fzf-tab

# history-substring-search: Search through your command history with arrow keys
zinit light zsh-users/zsh-history-substring-search

# you-should-use: Reminds you to use existing aliases instead of full commands
zinit ice wait lucid
zinit light MichaelAquilina/zsh-you-should-use

# autosuggestions: Suggests commands based on your history (grey text)
zinit light zsh-users/zsh-autosuggestions

# fast-syntax-highlighting: Colorizes your commands as you type
zinit light zdharma-continuum/fast-syntax-highlighting

# Reload changed plugins (makes things faster)
zinit cdreplay -q

# ----------------------------------------------------------------------
# KEYBINDINGS (Keyboard shortcuts)
# ----------------------------------------------------------------------
# Ctrl+P/N or Up/Down arrows: Search command history
# Ctrl+W: Kill (cut) the current word
# Note: Ctrl+C still cancels, Ctrl+V still pastes
bindkey -e
bindkey '^p' history-substring-search-up
bindkey '^n' history-substring-search-down
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[w' kill-region

# ----------------------------------------------------------------------
# HISTORY SETTINGS (Command history)
# ----------------------------------------------------------------------
# Saves 100,000 commands in your history file
# Removes duplicates and old entries to keep things clean
HISTSIZE=100000
HISTFILE=~/.zsh_history
SAVEHIST=100000
HISTDUP=erase
setopt appendhistory      # Append to history instead of overwriting
setopt sharehistory       # Share history between sessions
setopt hist_ignore_space  # Don't save commands starting with space
setopt hist_ignore_all_dups  # Don't save duplicate commands
setopt hist_save_no_dups   # Don't save duplicates to file
setopt hist_ignore_dups    # Ignore consecutive duplicates
setopt hist_find_no_dups   # When searching, skip duplicates

# ----------------------------------------------------------------------
# COMMAND CORRECTION
# ----------------------------------------------------------------------
# Automatically fixes typos in commands (e.g., 'gir' -> 'git')
setopt correct

# ----------------------------------------------------------------------
# COMPLETION STYLING (How suggestions look)
# ----------------------------------------------------------------------
# Makes tab-completion case-insensitive and colorful
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no

# Preview files when completing 'cd' commands (shows file list in fzf)
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --color=always $realpath'

# Preview file contents when completing 'bat', 'cat', 'nvim', etc.
zstyle ':fzf-tab:complete:(bat|cat|nvim|vim):*' fzf-preview 'bat --color=always --style=numbers $realpath || cat $realpath'
zstyle ':fzf-tab:complete:-command-:*' fzf-preview 'echo $word'

# ----------------------------------------------------------------------
# ALIASES (Shortcuts for commands)
# ----------------------------------------------------------------------
# Beginner Aliases (works on both macOS & Linux)
# These make your life easier - type the short alias, it runs the long command

# Navigation shortcuts - go up in directory
alias ..='cd ..'         # Go up 1 directory
alias ...='cd ../..'     # Go up 2 directories
alias ....='cd ../../..'  # Go up 3 directories
alias ~='cd ~'           # Go to home directory

# Listing shortcuts - better than plain 'ls'
alias ll='eza -l --icons=always --color=always'    # List files in detail
alias la='eza -la --icons=always --color=always'   # List ALL files (including hidden)
alias lla='eza -la --icons=always --color=always'  # List ALL files in detail
alias cl='clear && ls'  # Clear screen then list files

# Useful shortcuts
alias h='history'                      # View command history
alias psg='ps aux | grep -v grep | grep -i'  # Find running processes
alias myip='curl -s https://ifconfig.me && echo'  # Get your public IP
alias ports='ss -tulpn | grep LISTEN'    # Show open ports
alias dps='docker ps'                   # List running Docker containers
alias di='docker images'                # List Docker images

# System update (works on both Arch Linux and macOS)
# 'update' checks which package manager you have and updates accordingly
alias update='if command -v pacman &>/dev/null; then sudo pacman -Syu; elif command -v brew &>/dev/null; then brew update && brew upgrade; fi'

# Update pacman mirrors to fastest Indian servers (Arch Linux only)
alias upmirror='sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup && curl -fsSL "https://archlinux.org/mirrorlist/?country=IN&protocol=https&use_mirror_status=on" | sed -e "s/^#Server/Server/" | sudo tee /etc/pacman.d/mirrorlist > /dev/null && echo "Mirrorlist updated for India"'

# Core aliases (replacing default commands with better alternatives)
alias ls='eza --icons=always --color=always'    # eza is a modern 'ls'
alias cat='bat --style=plain --paging=never'     # bat is a better 'cat' with colors
alias zi='zoxide query -i'                      # Interactive cd with fuzzy search
alias vim='nvim'                                # Use Neovim instead of Vim
alias c='clear'                                 # Short for clear screen

# Git Aliases (shortcuts for Git commands)
# These save typing 'git' before every command
alias g='git'
alias ga='git add'              # Stage files
alias gaa='git add --all'       # Stage all changes
alias gcmsg='git commit -m'     # Commit with message
alias gco='git checkout'        # Switch branches
alias gl='git pull'             # Pull changes
alias gp='git push'             # Push changes
alias gst='git status'          # Show status
alias gd='git diff'             # Show changes

# ----------------------------------------------------------------------
# SHELL INTEGRATIONS
# ----------------------------------------------------------------------
# fzf: Fuzzy file finder (Ctrl+T to search files, Alt+C to cd into folders)
eval "$(fzf --zsh)"

# zoxide: Smarter cd - learns your frequently used folders
eval "$(zoxide init --cmd cd zsh)"

#-----------------------------------------------------------------------
#                            ENVIRONMENT
#-----------------------------------------------------------------------
# Sets default editors for various tools
export EDITOR=nano   # Default CLI editor
export VISUAL=nano   # Default GUI editor

#-----------------------------------------------------------------------
#                                PATH
#-----------------------------------------------------------------------
# PATH determines where your shell looks for commands
# This adds ~/.local/bin to your path so you can run personal scripts
typeset -U path # Keep duplicates out
path=(
  $HOME/.local/bin
  $path
)
export PATH

#-----------------------------------------------------------------------
#                           USER FUNCTIONS
#-----------------------------------------------------------------------
# Custom functions you can use in the terminal

# ex: Extract compressed files easily
# Usage: ex filename.tar.gz   (automatically detects file type)
ex() {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1   ;;
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
#                      ADVANCED WIDGETS
#-----------------------------------------------------------------------
# These are power-user features you can use once you're comfortable

# 0. Sudo Toggle (Press Escape twice)
# Example: If you type 'pacman -Syu' and realize you need sudo,
# press Esc twice to add 'sudo' to the beginning: 'sudo pacman -s yu'
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

# 1. Edit Command in Editor (Ctrl+X then Ctrl+E)
# Opens current command in your editor (nano by default) for complex edits
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

#-----------------------------------------------------------------------
#                      SUFFIX AND GLOBAL ALIASES
#-----------------------------------------------------------------------

# Suffix Aliases: Open files by just typing the filename
# Example: Just type 'readme.md' and it opens with bat (colored cat)
alias -s md=bat
alias -s txt=bat
alias -s log=bat
alias -s json=bat
alias -s yaml=bat
alias -s toml=bat

# Global Aliases: Use these ANYWHERE in a command (usually at the end)
# Example: ls G error   ->   ls | rg error
alias -g NE='2>/dev/null'        # Hide error messages
alias -g NO='>/dev/null'          # Hide output
alias -g NUL='>/dev/null 2>&1'   # Hide everything
alias -g G='| rg'                 # Quick grep (ripgrep)

#-----------------------------------------------------------------------
#     OS-SPECIFIC (Delete sections not applicable to your OS)
#-----------------------------------------------------------------------

# --- Arch Linux / WSL specific ---
# Uncomment/delete this block if on macOS
# zinit snippet OMZP::archlinux    # Arch-specific completions
# alias up='paru'                   # AUR helper shortcut

# --- macOS specific ---
# Uncomment/delete this block if on Arch Linux
# export PATH="/opt/homebrew/bin:$PATH"  # Apple Silicon homebrew path
# alias open-finder='open .'            # Open current folder in Finder