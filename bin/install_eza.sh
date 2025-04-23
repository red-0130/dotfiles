#!/bin/env bash

if command -v eza &>/dev/null; then
  echo "eza is already installed"
else
  sudo apt install eza -y
fi
