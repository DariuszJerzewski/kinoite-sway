#!/usr/bin/env bash
set -oue pipefail

useradd -D -s /bin/zsh

git clone https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh
chmod -R 755 /usr/share/oh-my-zsh

cp /usr/share/oh-my-zsh/templates/zshrc.zsh-template /etc/skel/.zshrc
sed -i 's|export ZSH=$HOME/.oh-my-zsh|export ZSH=/usr/share/oh-my-zsh|' /etc/skel/.zshrc
