# Run cargo clippy and bevy lint.
check *args:
    cargo clippy {{args}}
    bevy lint {{args}}

NIXGL := env("NIXGL", "nixVulkanNvidia")

# Play the given binary.
# This requires no '-p' flag so we can properly set the BEVY_ASSET_ROOT.
play package *args:
    #!/bin/bash
    if [[ "{{package}}" == "-p" || "{{package}}" == "--package" || "{{args}}" == *-p* ]]; then
        echo "Usage: 'just play <bin> [args]'"
        echo "Use the first argument to specify the package."
        exit 1;
    fi
    export BEVY_ASSET_ROOT=./bin/{{package}}
    nix run --impure github:nix-community/nixGL#{{ NIXGL }} -- \
        uv run .infra/scripts/src/qproj_scripts/ play -p {{package}} {{args}}

# Arguments passed directly to nextest
test *args:
    cargo nextest run {{args}}

# Scaffold a crate from the infra template (dry-run unless -x is supplied).
init path *args:
    #!/usr/bin/env bash
    read -r -a options <<< {{ quote(args) }}
    uv run .infra/scripts/src/qproj_scripts/ init {{ quote(file_name(path)) }} \
        --{{ quote(file_name(parent_directory(path))) }} \
        --dest {{ quote(path) }} \
        --bevy-version {{ quote(trim(read(".infra/.bevy-version"))) }} \
        --registry .infra/downstream-repos.json \
        --workspace Cargo.toml \
        "${options[@]}"
