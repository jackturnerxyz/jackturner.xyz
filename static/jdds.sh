#!/bin/bash
# J.D.D.S. - Jack's Dotfile Deployment Script for Arch GNU/Linux
#
# Enhanced and optimized for robustness, readability, and user experience.

# ---
# Exit on error, treat unset variables as an error, and ensure pipelines fail on error.
# ---
set -euo pipefail

# ---
# Configuration Variables
# ---
readonly SUDO_PROGRAM="sudo"
readonly DOTFILES_REPO="https://github.com/jackturnerxyz/dotfiles.git"
readonly FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
readonly FONT_ZIP_NAME="JetBrainsMono.zip"

# Packages required for the setup
readonly PACMAN_PACKAGES=(
    # Core environment
    hyprland
    waybar
    git
    zsh
    neovim
    foot
    firefox
    
    # Utilities
    rofi
    btop
    glow
    zathura
    hyprpaper
    wget
    unzip
    wl-clipboard

    # Audio
    mpd
    mpc
    ncmpcpp
    pipewire
    pipewire-pulse
    pipewire-jack
    pulsemixer
)

# ---
# Color definitions for script output
# ---
readonly C_RESET='\033[0m'
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[0;33m'
readonly C_BLUE='\033[0;34m'

# ---
# Helper functions for logging
# ---
info() {
    echo -e "${C_BLUE}INFO:${C_RESET} $1"
}

success() {
    echo -e "${C_GREEN}SUCCESS:${C_RESET} $1"
}

warn() {
    echo -e "${C_YELLOW}WARNING:${C_RESET} $1"
}

error() {
    echo -e "${C_RED}ERROR:${C_RESET} $1" >&2
    exit 1
}

# ---
# Main Logic Functions
# ---

# Function to check for essential commands
check_dependencies() {
    info "Checking for required commands..."
    local missing_deps=0
    for cmd in git wget unzip pacman; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "${C_RED}- $cmd is not found.${C_RESET}"
            missing_deps=1
        else
            echo -e "${C_GREEN}- $cmd is present.${C_RESET}"
        fi
    done
    
    if [[ "$missing_deps" -eq 1 ]]; then
        error "Please install the missing commands before running this script."
    fi
}

# Function to install packages using pacman
install_packages() {
    info "Installing required packages with pacman..."
    # Using --needed ensures we don't reinstall packages that are already up to date.
    $SUDO_PROGRAM pacman -Syu --needed "${PACMAN_PACKAGES[@]}"
    success "Package installation complete."
}

# Function to clone dotfiles and copy them to the correct locations
setup_dotfiles() {
    info "Cloning dotfiles from repository..."
    git clone "$DOTFILES_REPO" dotfiles

    info "Setting up configuration directories..."
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/share/fonts"

    info "Copying configuration files..."
    cp -r dotfiles/.config/* "$HOME/.config/"
    
    info "Copying shell configuration..."
    cp dotfiles/.zshrc dotfiles/.zprofile "$HOME/" # Note: .zshev is less common, changed to .zprofile

    info "Copying local binaries..."
    # Corrected the typo 'dotfile' to 'dotfiles' and ensure scripts are executable
    if [ -d "dotfiles/.local/bin" ] && [ -n "$(ls -A dotfiles/.local/bin)" ]; then
        cp dotfiles/.local/bin/* "$HOME/.local/bin/"
        chmod +x "$HOME"/.local/bin/*
        success "Local binaries copied and made executable."
    else
        warn "No local binaries found to copy."
    fi

    info "Copying wallpaper..."
    cp dotfiles/bg.jpg "$HOME/"
    
    success "Dotfiles have been deployed."
}

# Function to download and install fonts
install_fonts() {
    info "Downloading and installing JetBrains Mono Nerd Font..."
    wget -O "$FONT_ZIP_NAME" "$FONT_URL"
    unzip -o "$FONT_ZIP_NAME" -d "$HOME/.local/share/fonts"
    
    info "Updating font cache..."
    fc-cache -fv
    
    success "Font installation complete."
}

# Function to install Oh My Zsh and plugins
setup_zsh() {
    info "Installing Oh My Zsh..."
    # The installer is downloaded and run non-interactively
    wget -O install-omz.sh https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
    chmod +x install-omz.sh
    # KEEP_ZSHRC prevents overwriting our .zshrc; RUNZSH=no prevents it from launching a new shell
    KEEP_ZSHRC='yes' RUNZSH='no' ./install-omz.sh
    
    info "Installing Zsh plugins..."
    local zsh_custom="$HOME/.oh-my-zsh/custom"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${zsh_custom}/plugins/zsh-syntax-highlighting"
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "${zsh_custom}/plugins/zsh-autosuggestions"
    
    success "Oh My Zsh and plugins are installed."
}

# ---
# Main Execution
# ---
main() {
    # Create a temporary directory for all operations
    # The 'trap' command ensures this directory is cleaned up on script exit (success or failure)
    TMP_DIR=$(mktemp -d /tmp/jdds.XXXXXX)
    trap 'info "Cleaning up temporary directory..."; rm -rf -- "$TMP_DIR"' EXIT
    
    # Move to the temporary directory
    cd "$TMP_DIR"
    
    check_dependencies
    install_packages
    setup_dotfiles
    install_fonts
    setup_zsh

    # Final steps
    info "Changing default shell to Zsh. You may be prompted for your password."
    if chsh -s /bin/zsh; then
        success "Default shell changed to /bin/zsh."
    else
        error "Failed to change shell. Please run 'chsh -s /bin/zsh' manually."
    fi
    
    echo
    success "All tasks completed!"
    info "Please log out and log back in for all changes to take effect."
}

# ---
# Script entry point
# ---

# Ask for confirmation before proceeding
echo "J.D.D.S. - Jack's Dotfile Deployment Script"
echo "-------------------------------------------"
echo "This script will:"
echo "  1. Install a list of packages via pacman."
echo "  2. Clone dotfiles from ${DOTFILES_REPO} and deploy them."
echo "  3. Install the JetBrains Mono Nerd Font."
echo "  4. Install Oh My Zsh and selected plugins."
echo "  5. Change your default shell to Zsh."
echo
read -p "Do you want to proceed? (y/N): " choice
case "$choice" in 
  y|Y )
    main
    ;;
  * )
    info "Installation aborted by user."
    exit 0
    ;;
esac
