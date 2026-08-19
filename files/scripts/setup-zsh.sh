#!/usr/bin/env bash
set -oue pipefail

useradd -D -s /bin/zsh

# Clone repos
git clone https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh
git clone https://github.com/zsh-users/zsh-autosuggestions.git /usr/share/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /usr/share/zsh-syntax-highlighting

cp /usr/share/oh-my-zsh/templates/zshrc.zsh-template /etc/skel/.zshrc

# Use the shared Oh My Zsh installation
sed -i 's|^export ZSH=.*|export ZSH=/usr/share/oh-my-zsh|' /etc/skel/.zshrc

# Import system-wide plugins
cat >> /etc/skel/.zshrc <<'EOF'

# Load system-wide Zsh plugins
source /etc/zsh/plugins.zsh
EOF
