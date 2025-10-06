#!/bin/bash
# J.D.D.S. - Jack's Dotfile Deployment Script for Arch GNU/Linux
#
# Enhanced and optimized for robustness, readability, and user experience.
# Version 4: Automatically installs missing base commands (git, wget, etc.).

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
readonly AUR_HELPER_REPO="https://aur.archlinux.org/paru.git"

# Packages required for the setup
readonly PACMAN_PACKAGES=(
    # Core environment & Display Manager
    hyprland waybar git zsh neovim foot firefox sddm

    # Build tools for AUR
    base-devel

    # Utilities
    rofi btop glow zathura hyprpaper wget unzip wl-clipboard

    # Audio
    mpd mpc ncmpcpp pipewire pipewire-pulse pipewire-jack pulsemixer
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

# Function to check for and install missing base commands
check_dependencies() {
    info "Checking for required base commands..."
    # If pacman isn't available, we can't do anything. This is a fatal error.
    if ! command -v pacman &>/dev/null; then
        error "'pacman' command not found. This script is designed for Arch Linux."
    fi

    local missing_pkgs=()
    # For these packages, the command name is the same as the package name.
    local core_commands=("git" "wget" "unzip")

    for cmd in "${core_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_pkgs+=("$cmd")
        fi
    done

    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        warn "The following essential commands are missing and will be installed: ${missing_pkgs[*]}"
        $SUDO_PROGRAM pacman -Syu --needed --noconfirm "${missing_pkgs[@]}"
        success "Missing base commands have been installed."
    else
        success "All base commands are present."
    fi
}

# Function to install pacman packages only if they are not already installed
install_packages() {
    info "Checking for required pacman packages..."
    local packages_to_install=()
    for pkg in "${PACMAN_PACKAGES[@]}"; do
        # pacman -Q returns a non-zero exit code if the package is not found
        if ! pacman -Q "$pkg" &>/dev/null; then
            packages_to_install+=("$pkg")
        fi
    done

    if [ ${#packages_to_install[@]} -gt 0 ]; then
        info "The following packages need to be installed:"
        printf "  - %s\n" "${packages_to_install[@]}"
        
        # Using --needed tells pacman to skip packages that are already installed.
        $SUDO_PROGRAM pacman -Syu --needed --noconfirm "${packages_to_install[@]}"
        success "Missing packages have been installed."
    else
        success "All required pacman packages are already installed. Syncing repositories..."
        $SUDO_PROGRAM pacman -Syyu --noconfirm
    fi
}


# Function to install an AUR helper (paru)
install_aur_helper() {
    info "Checking for AUR helper (paru)..."
    if command -v paru &>/dev/null; then
        success "AUR helper (paru) is already installed."
        return
    fi

    info "Paru not found. Building and installing from AUR..."
    local build_dir
    build_dir=$(mktemp -d)

    git clone "$AUR_HELPER_REPO" "$build_dir"
    (
        cd "$build_dir" || exit
        makepkg -si --noconfirm
    )

    success "Paru has been successfully installed."
}

# Function to clone dotfiles and copy them to the correct locations
setup_dotfiles() {
    info "Cloning dotfiles from repository..."
    git clone "$DOTFILES_REPO" dotfiles

    info "Setting up configuration directories..."
    mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/fonts"

    info "Copying configuration files..."
    cp -r dotfiles/.config/* "$HOME/.config/"

    info "Copying shell configuration..."
    cp dotfiles/.zshrc dotfiles/.zprofile "$HOME/"

    info "Copying local binaries..."
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
    info "Checking for JetBrains Mono Nerd Font..."
    if fc-list | grep -q "JetBrainsMono Nerd Font"; then
        success "JetBrains Mono Nerd Font is already installed."
        return
    fi
    
    info "Downloading and installing JetBrains Mono Nerd Font..."
    wget -O "$FONT_ZIP_NAME" "$FONT_URL"
    unzip -o "$FONT_ZIP_NAME" -d "$HOME/.local/share/fonts"

    info "Updating font cache..."
    fc-cache -fv

    success "Font installation complete."
}

# Function to install Oh My Zsh and plugins
setup_zsh() {
    info "Checking for Oh My Zsh..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        success "Oh My Zsh is already installed."
    else
        info "Installing Oh My Zsh..."
        wget -O install-omz.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
        KEEP_ZSHRC='yes' RUNZSH='no' CHSH='no' sh install-omz.sh
        success "Oh My Zsh has been installed."
    fi

    info "Installing Zsh plugins..."
    local zsh_custom="$HOME/.oh-my-zsh/custom"
    if [ ! -d "${zsh_custom}/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${zsh_custom}/plugins/zsh-syntax-highlighting"
    fi
    if [ ! -d "${zsh_custom}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions.git "${zsh_custom}/plugins/zsh-autosuggestions"
    fi
    success "Zsh plugins are configured."
}

# Function to enable the display manager
setup_display_manager() {
    info "Checking SDDM service status..."
    if systemctl is-enabled --quiet sddm.service; then
        success "SDDM service is already enabled."
    else
        info "Enabling the SDDM display manager..."
        $SUDO_PROGRAM systemctl enable sddm.service
        success "SDDM has been enabled. It will start on the next boot."
    fi
}


# ---
# Main Execution
# ---
main() {
    TMP_DIR=$(mktemp -d /tmp/jdds.XXXXXX)
    trap 'info "Cleaning up temporary directory..."; rm -rf -- "$TMP_DIR"' EXIT
    cd "$TMP_DIR"

    check_dependencies
    install_packages
    install_aur_helper
    setup_dotfiles
    install_fonts
    setup_zsh
    setup_display_manager

    info "Changing default shell to Zsh. You may be prompted for your password."
    if [[ "$SHELL" != "/bin/zsh" ]]; then
        if chsh -s /bin/zsh; then
            success "Default shell changed to /bin/zsh."
        else
            error "Failed to change shell. Please run 'chsh -s /bin/zsh' manually."
        fi
    else
        success "Default shell is already Zsh."
    fi

    echo
    success "All tasks completed!"
    warn "A reboot is recommended for all changes to take full effect."
}

# ---
# Script entry point
# ---

echo "J.D.D.S. - Jack's Dotfile Deployment Script (v4)"
echo "------------------------------------------------"
echo "This script will check for and install missing components for a complete desktop setup."
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
