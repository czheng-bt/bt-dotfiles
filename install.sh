#!/usr/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v zsh >/dev/null 2>&1
then
  sudo yum install zsh -y
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

if [ ! -f "$HOME/.zshrc" ]; then
  ln -s "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
fi
