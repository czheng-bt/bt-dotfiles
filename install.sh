#!/usr/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function install_zsh() {
  if command -v zsh &> /dev/null
  then
    return
  fi

  if command -v apt &> /dev/null
  then
    sudo apt update
    sudo apt install zsh -y
  elif command -v dnf &> /dev/null
  then
    sudo dnf install zsh -y
  else
    echo "Unsupported package manager. Please install zsh manually."
    exit 1
  fi
}

install_zsh

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

if [ ! -f "$HOME/.zshrc" ]; then
  ln -s "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
fi
