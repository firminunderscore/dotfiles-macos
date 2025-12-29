#!/bin/bash
set -e

# Colors
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

log_info() { echo -e "${BOLD}${GREEN}[INFO]${RESET} $1"; }
log_warn() { echo -e "${BOLD}${YELLOW}[WARN]${RESET} $1"; }
log_error() { echo -e "${BOLD}${RED}[ERROR]${RESET} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# 1. SYSTEM PRE-REQS (Xcode & Homebrew)
# ==============================================================================
install_xcode_cli() {
    log_info "Checking Xcode Command Line Tools..."
    if ! xcode-select -p &>/dev/null; then
        log_info "Installing Xcode Command Line Tools..."
        xcode-select --install
        echo "Press any key after the installation is complete..."
        read -n 1 -s
    else
        log_info "Xcode Command Line Tools already installed"
    fi
}

install_homebrew() {
    log_info "Checking Homebrew..."
    if ! command -v brew &>/dev/null; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH
        if [[ $(uname -m) == "arm64" ]]; then
            if [[ -f /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
        else
            if [[ -f /usr/local/bin/brew ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi
    else
        log_info "Homebrew already installed"
    fi
    
    # Ensure brew is available before updating
    if command -v brew &>/dev/null; then
        log_info "Updating Homebrew..."
        brew update
    else
        log_warn "Homebrew installation may have failed or PATH is not set correctly."
    fi
}

# ==============================================================================
# 2. PACKAGES INSTALLATION
# ==============================================================================
install_packages() {
    # Taps
    log_info "Tapping repositories..."
    brew tap psharma04/dorion

    # Helper function to read list files (ignoring comments and empty lines)
    read_list_file() {
        local list_file="$1"
        if [[ -f "$list_file" ]]; then
            grep -vE '^\s*#|^\s*$' "$list_file"
        else
            log_warn "File not found: $list_file"
        fi
    }

    log_info "Installing Homebrew formulae..."
    local formulae_file="$SCRIPT_DIR/pkglist/formulae.txt"
    if [[ -f "$formulae_file" ]]; then
        while IFS= read -r formula; do
            if brew list "$formula" &>/dev/null; then
                log_info "$formula already installed"
            else
                log_info "Installing $formula..."
                brew install "$formula" || log_warn "Failed to install $formula"
            fi
        done < <(read_list_file "$formulae_file")
    else
        log_error "Formulae list file missing: $formulae_file"
    fi
    
    log_info "Installing Homebrew casks..."
    local casks_file="$SCRIPT_DIR/pkglist/casks.txt"
    if [[ -f "$casks_file" ]]; then
        while IFS= read -r cask; do
            cask_name=$(basename "$cask")
            if brew list --cask "$cask_name" &>/dev/null; then
                log_info "$cask_name already installed"
            else
                log_info "Installing $cask_name (using --force)..."
                brew install --cask --force "$cask" || log_warn "Failed to install $cask_name"
            fi
        done < <(read_list_file "$casks_file")
    else
        log_error "Casks list file missing: $casks_file"
    fi
}

setup_fish() {
    log_info "Setting up Fish shell..."
    local FISH_PATH=$(which fish)
    if ! grep -q "$FISH_PATH" /etc/shells; then
        log_info "Adding Fish to /etc/shells..."
        echo "$FISH_PATH" | sudo tee -a /etc/shells
    fi
    
    if [[ "$SHELL" != "$FISH_PATH" ]]; then
        log_info "Setting Fish as default shell..."
        chsh -s "$FISH_PATH"
    fi
    
    # Install Fisher if missing
    if ! fish -c "type fisher" &>/dev/null; then
        log_info "Installing Fisher plugin manager..."
        fish -c "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher" 2>/dev/null || true
    fi

    # Install plugins from list
    log_info "Installing Fish plugins..."
    local fisher_file="$SCRIPT_DIR/pkglist/fisher.txt"
    if [[ -f "$fisher_file" ]]; then
        while IFS= read -r plugin; do
            log_info "Installing plugin: $plugin"
            fish -c "fisher install $plugin" || log_warn "Failed to install plugin: $plugin"
        done < <(grep -vE '^\s*#|^\s*$' "$fisher_file")
    else
        log_warn "Fisher plugins list missing: $fisher_file"
    fi

    log_info "Creating hushlogin file..."
    if [[ -f ~/.hushlogin ]]; then
        log_info "Hushlogin file already exists"
    else
        touch ~/.hushlogin
        log_info "Hushlogin file created"
    fi
}

setup_sketchybar() {
    log_info "Setting up Sketchybar..."
    if [ ! -f "$HOME/Library/Fonts/sketchybar-app-font.ttf" ]; then
        log_info "Installing Sketchybar app font..."
        curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.28/sketchybar-app-font.ttf -o ~/Library/Fonts/sketchybar-app-font.ttf 2>/dev/null || true
    fi
    brew services start sketchybar 2>/dev/null || true
}

# ==============================================================================
# 3. DOTFILES (STOW)
# ==============================================================================
install_dotfiles() {
    log_info "Installing dotfiles with stow..."
    
    # Check if stow is installed
    if ! command -v stow &>/dev/null; then
        log_warn "Stow is not installed. Attempting to install via brew..."
        if command -v brew &>/dev/null; then
            brew install stow
        else
            log_error "Brew not found. Cannot install stow. Please install stow manually."
            return 1
        fi
    fi
    
    cd "$SCRIPT_DIR"
    mkdir -p ~/.config
    mkdir -p ~/.config/fish # Ensure fish config folder exists so stow links files, not the folder
    
    local PACKAGES=(
        aerospace
        fastfetch
        fish
        ghostty
        sketchybar
        starship
        tmux
    )
    
    for package in "${PACKAGES[@]}"; do
        if [[ -d "$package" ]]; then
            log_info "Stowing $package..."
            stow --restow "$package" 2>/dev/null || log_warn "Failed to stow $package (conflicts may exist)"
        fi
    done
}

# ==============================================================================
# 4. MACOS PREFERENCES
# ==============================================================================
setup_macos_preferences() {
    log_info "Configuring macOS preferences (matching current system)..."
    
    osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true
    
    # --- Keyboard ---
    log_info "Setting Keyboard preferences..."
    # System Settings > Keyboard > Key repeat rate
    defaults write NSGlobalDomain KeyRepeat -int 5
    # System Settings > Keyboard > Delay until repeat
    defaults write NSGlobalDomain InitialKeyRepeat -int 30
    
    # --- Finder ---
    log_info "Setting Finder preferences..."
    # Finder > View > Show Path Bar
    defaults write com.apple.finder ShowPathbar -bool true
    # Finder > View > Show Status Bar
    defaults write com.apple.finder ShowStatusBar -bool true
    
    # --- Dock & Mission Control ---
    log_info "Setting Dock preferences..."
    # System Settings > Desktop & Dock > Automatically hide and show the Dock
    defaults write com.apple.dock autohide -bool true
    # (Hidden Preference) Remove the animation delay for showing the Dock
    defaults write com.apple.dock autohide-delay -float 0
    # System Settings > Desktop & Dock > Size (slider)
    defaults write com.apple.dock tilesize -int 66
    # System Settings > Desktop & Dock > Magnification
    defaults write com.apple.dock magnification -bool false
    # System Settings > Desktop & Dock > Minimize windows into application icon
    defaults write com.apple.dock minimize-to-application -bool true
    # System Settings > Desktop & Dock > Mission Control > Automatically rearrange Spaces based on most recent use
    defaults write com.apple.dock mru-spaces -bool false
    # System Settings > Desktop & Dock > Show suggested and recent apps in Dock
    defaults write com.apple.dock show-recents -bool true
    # System Settings > Desktop & Dock > Show indicators for open applications
    defaults write com.apple.dock show-process-indicators -bool true
    # (Hidden Preference) Make hidden applications translucent in the Dock
    defaults write com.apple.dock showhidden -bool true
    # System Settings > Desktop & Dock > Mission Control > Group windows by application
    defaults write com.apple.dock expose-group-apps -bool true
    
    # --- Window Management ---
    log_info "Setting Window Management preferences..."
    # (Hidden Preference) Drag windows by clicking anywhere on them with Ctrl+Cmd
    defaults write NSGlobalDomain NSWindowShouldDragOnGesture -bool true
    
    # --- Screenshots ---
    log_info "Setting Screenshot preferences..."
    # (Partially hidden) Set default location for screenshots
    mkdir -p ~/Pictures/Screenshots
    defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"
    
    # --- Spotlight ---
    log_info "Disabling Spotlight shortcut (Command+Space)..."
    # Disable "Show Spotlight Search" hotkey (Command+Space) to prevent conflict with Raycast
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "{ enabled = 0; value = { parameters = (32, 49, 1048576); type = 'standard'; }; }"

    # --- Raycast ---
    log_info "Setting Raycast preferences..."
    # Enable Hyper Key (Caps Lock maps to Hyper)
    defaults write com.raycast.macos raycast_hyperKey_state -dict enabled -bool true keyCode -int 57 includeShiftKey -bool false
    defaults write com.raycast.macos useHyperKeyIcon -bool true
    # Set Raycast Global Hotkey to Command+Space (Command-49)
    defaults write com.raycast.macos raycastGlobalHotkey -string "Command-49"
    
    # Restart apps to apply changes
    for app in "Finder" "Dock" "SystemUIServer"; do
        killall "$app" &>/dev/null || true
    done
}

# ==============================================================================
# MAIN ENTRY POINT
# ==============================================================================
show_usage() {
    echo "Usage: ./install.sh [OPTIONS]"
    echo "Options:"
    echo "  --all        Run full setup (default if no args)"
    echo "  --dotfiles   Link dotfiles only (stow)"
    echo "  --packages   Install Homebrew & packages only"
    echo "  --macos      Apply macOS preferences only"
    echo "  --help       Show this help message"
}

run_full_setup() {
    echo -e "${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║            FirminUnderscore's Mac Setup Script                ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    
    echo "This script will install:"
    echo "  - Xcode CLI & Homebrew"
    echo "  - Packages & Apps"
    echo "  - Dotfiles (stow)"
    echo "  - macOS Preferences"
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "Aborted"
        exit 1
    fi
    
    install_xcode_cli
    install_homebrew
    install_packages
    install_dotfiles
    setup_fish
    # setup_sketchybar (I don't use it anymore)
    
    read -p "Apply macOS preferences? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_macos_preferences
    fi
    
    log_info "Setup complete!"
}

# Argument parsing
if [[ $# -eq 0 ]]; then
    run_full_setup
else
    for arg in "$@"; do
        case $arg in
            --dotfiles)
                install_dotfiles
                ;;
            --packages)
                install_xcode_cli
                install_homebrew
                install_packages
                setup_fish
                # setup_sketchybar (I don't use it anymore)
                ;;
            --macos)
                setup_macos_preferences
                ;;
            --all)
                run_full_setup
                ;;
            --help)
                show_usage
                ;;
            *)
                log_error "Unknown option: $arg"
                show_usage
                exit 1
                ;;
        esac
    done
fi
