# Run cargo clippy.
check *args:
    cargo clippy {{ args }}

warn_du:
    #!/usr/bin/env python3
    import subprocess
    import os
    if os.path.exists("./target"):
        du=subprocess.run(['du', './target', '-s'], capture_output=True, text=True)
        gb = int(du.stdout.split('\t')[0]) / (1024 * 1024)
        print(f"du ./target => {gb:0.2f} GB")
        df=subprocess.run(['df', './target', '--output=pcent'], capture_output=True, text=True)
        free_pct = df.stdout.split('\n')[1].strip()[:-1]
        print(f"df ./target => {free_pct}%")
        if int(free_pct) > 90:
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
    uv run misc/infra/scripts/src/qproj_scripts/ play -p {{ package }} {{ args }}

# Arguments passed directly to nextest
test *args: warn_du
    cargo nextest run {{ args }}

# Scaffold a crate from the infra template (dry-run unless -x is supplied).
init path *args:
    #!/usr/bin/env bash
    read -r -a options <<< {{ quote(args) }}
    uv run misc/infra/scripts/src/qproj_scripts/ init {{ quote(file_name(path)) }} \
        --{{ quote(file_name(parent_directory(path))) }} \
        --dest {{ quote(path) }} \
        --bevy-version {{ quote(trim(read("misc/infra/.bevy-version"))) }} \
        --registry misc/infra/downstream-repos.json \
        --workspace Cargo.toml \
        "${options[@]}"

# Initial set-up. Clones repos from repos.yml, removes extras.
setup:
    #!/usr/bin/env -S uv run --script
    # /// script
    # requires-python = ">=3.12"
    # dependencies = ["pyyaml"]
    # ///
    import shutil
    import subprocess
    import sys
    from os.path import expanduser
    from pathlib import Path

    import yaml

    root = Path.cwd()
    groups = yaml.safe_load((root / "repos.yml").read_text())

    # Expected checkout path -> clone URL.
    expected = {}
    group_dirs = set()
    for group in groups:
        for group_name, entries in group.items():
            group_dirs.add(root / group_name)
            for entry in entries:
                path = entry.get("path", f"{group_name}/{entry['name']}")
                expected[root / path] = expanduser(entry["repo"])

    failures = []
    for path, url in sorted(expected.items()):
        rel = path.relative_to(root)
        if path.exists():
            print(f"ok      {rel}")
            continue
        print(f"clone   {rel} <- {url}")
        if subprocess.run(["git", "clone", "--recurse-submodules", url, str(path)]).returncode:
            failures.append(rel)

    for group_dir in sorted(group_dirs):
        if not group_dir.is_dir():
            continue
        for child in sorted(group_dir.iterdir()):
            if child in expected:
                continue
            print(f"remove  {child.relative_to(root)} (not in repos.yml)")
            if child.is_dir():
                shutil.rmtree(child)
            else:
                child.unlink()

    if failures:
        print("failed to clone:")
        for rel in failures:
            print(f"  {rel}")
        sys.exit(1)
