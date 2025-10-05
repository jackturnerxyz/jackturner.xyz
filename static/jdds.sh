#!/bin/sh
# J.D.D.S. - Jack's Dotfile Deployment Script for Arch GNU/Linux

# Environment Variables
SUDO_PROGRAM="sudo" # alternative: "doas"

dep_pkgs_pacman="hyprland waybar git mpd mpc ncmpcpp zsh neovim rofi btop glow zathura hyprpaper pipewire pipewire-pulse pipewire-jack pulsemixer foot firefox wget unzip wl-clipboard"

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
cd
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# Install dep
$SUDO_PROGRAM pacman -S $dep_pkgs_pacman
#wallpaper
cd $tmp_install_dir 
cp dotfiles/bg.jpg ~/
# Finishing touches
chsh -s /bin/zsh

echo "Done."
