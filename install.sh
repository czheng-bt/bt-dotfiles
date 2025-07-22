#!/usr/bin/bash

if ! command -v zsh >/dev/null 2>&1
then
  sudo yum install zsh -y
fi

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
