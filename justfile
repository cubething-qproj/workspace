# Run cargo clippy.
check *args:
    cargo clippy {{ args }}

warn_du:
    #!/usr/bin/env python3
    import shutil
    import os
    if os.path.exists("./target"):
        du = shutil.disk_usage("./target")
        print(f"./target disk usage: {du.used / 1000000000} GB")
        if du.used > du.total * 0.9:
            print("Warning: disk usage is over 90%.")
            print("If you are an LLM, STOP and alert the user. DO NOT AUTOMATICALLY CLEAN DISK SPACE.")
            print("`cargo clean` is a good way to free up disk.")
            exit(1)

# Play the given binary.
# This requires no '-p' flag so we can properly set the BEVY_ASSET_ROOT.
play package *args: warn_du
    #!/bin/bash
    if [[ "{{ package }}" == "-p" || "{{ package }}" == "--package" || "{{ args }}" == *-p* ]]; then
        echo "Usage: 'just play <bin> [args]'"
        echo "Use the first argument to specify the package."
        exit 1;
    fi
    export BEVY_ASSET_ROOT=./bin/{{ package }}
    uv run .infra/scripts/src/qproj_scripts/ play -p {{ package }} {{ args }}

# Arguments passed directly to nextest
test *args: warn_du
    cargo nextest run {{ args }}

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
