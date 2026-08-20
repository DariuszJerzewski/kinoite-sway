#!/usr/bin/env bash
set -oue pipefail

useradd -D -s /bin/zsh

# Clone repos
git clone https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh
git clone https://github.com/zsh-users/zsh-autosuggestions.git /usr/share/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /usr/share/zsh-syntax-highlighting
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /usr/share/oh-my-zsh/custom/themes/powerlevel10k
