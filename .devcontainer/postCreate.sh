#!/bin/bash
set -e

echo "[postCreate] Setting up unified Dev-Stack workspace..."

# Load aliases
if [ -f /workspaces/${localWorkspaceFolderBasename}/.bash_aliases ]; then
    grep -qxF 'source ~/.bash_aliases' ~/.bashrc || echo "source ~/.bash_aliases" >> ~/.bashrc
    echo "[postCreate] Aliases linked"
fi

# Git colors
git config --global color.ui auto
git config --global color.branch auto
git config --global color.diff auto
git config --global color.status auto
git config --global color.interactive auto

# Init/update submodules
git submodule update --init --recursive

echo "[postCreate] Workspace ready"
