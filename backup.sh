#!/bin/bash

FILES=(
    ".config/fastfetch/"
    ".config/fish/config.fish"
    ".config/ghostty/"
    ".config/starship.toml"
    ".hushlogin"
)

for file in "${FILES[@]}"; do
    # Create destination directory if it doesn't exist
    dest_dir=$(dirname "./${file}")
    mkdir -p "${dest_dir}"

    # Copy from home directory using $HOME instead of ~
    if [ -e "${HOME}/${file}" ]; then
        cp -r "${HOME}/${file}" "./${file}"
        echo "Backed up: ${file}"
    else
        echo "Warning: ${HOME}/${file} does not exist"
    fi
done
