#!/bin/sh
# J.D.D.S. - Jack's Dotfile Deployment Script for Arch GNU/Linux

# Environment Variables
SUDO_PROGRAM="sudo" # alternative: "doas"

dep_pkgs_pacman="hyprland waybar git mpd mpc ncmpcpp zsh neovim rofi btop glow zathura hyprpaper pipewire pipewire-pulse pipewire-jack pulsemixer foot firefox wget unzip wl-clipboard"

$SUDO_PROGRAM pacman -S $dep_pkgs_pacman

tmp_install_dir=$(mktemp -d /tmp/jdds.XXXX)
cd $tmp_install_dir

git clone https://github.com/jackturnerxyz/dotfiles.git

mkdir ~/.config
mkdir -p ~/.local/bin

cp -r dotfiles/.config/* ~/.config/
cp dotfiles/.zshrc dotfiles/.zshev ~/
cp dotfile/.local/bin/* ~/.local/bin/

# Font install

wget "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
mkdir -p ~/.local/share/fonts
unzip JetBrainsMono.zip -d ~/.local/share/fonts

# Oh my ZSH
wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
chmod +x install.sh
CHSH='no' RUNZSH='no' KEEP_ZSHRC='yes' ./install.sh

cd
export ZSH_CUSTOM="~/.oh-my-zsh"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions

# Install dep
#wallpaper
cd $tmp_install_dir 
cp dotfiles/bg.jpg ~/
# Finishing touches
chsh -s /bin/zsh

echo "Done."
