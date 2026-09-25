# Simplify `init` for the single-workspace layout

Status: **Approved; implementation underway one step at a time.**

Decision after review: delete `sync`; `.gitignore`, `.zed/settings.json`, and `justfile` are **init-only**, not overwritten by downstream CI sync.

## Goal

From the org root:

```sh
just init lib/q_cam              # dry run: print every action
just init lib/q_cam -x           # scaffold, verify, commit, create public repo, push, register via PR
just init bin/foo -x             # same, binary crate
just init lib/q_cam -x --no-remote   # local only: scaffold, verify, commit. No GitHub, no .infra edits
```

The result is a fully templated crate. It joins the root workspace immediately
(`members = ["bin/*", "lib/*"]`) and is still its own GitHub repo.

## Split: portable script, layout-aware wrapper

`qproj-scripts init` knows nothing about the org layout. All paths come from the
root `justfile`, so a future layout change only touches the wrapper.

```just
# Scaffold a new crate: just init lib/<name> [-x] [--no-remote] [--private]
init path *args:
    uv run .infra/scripts/src/qproj_scripts/ init {{ file_name(path) }} \
        --{{ file_name(parent_directory(path)) }} \
        --dest {{ path }} \
        --bevy-version {{ trim(read(".infra/.bevy-version")) }} \
        --registry .infra/downstream-repos.json \
        --workspace Cargo.toml \
        {{ args }}
```

- `lib/q_cam` becomes crate `q_cam` with `--lib`. `bin/foo` becomes `foo` with `--bin`. Any other parent,
  e.g. `src/x`, becomes `--src`, which Typer rejects as an unknown option.
- The script validates `NAME` as a bare Rust identifier, so no `/`.

### Script CLI

```
qproj-scripts init NAME (--lib|--bin) --dest PATH --bevy-version V
                   [--registry PATH] [--workspace PATH] [-x] [--no-remote] [--private]
```

| Arg | Behavior |
| --- | --- |
| `--lib`/`--bin` | Required. Picks whether `src/lib.rs` or `src/main.rs` is copied. |
| `--dest` | Target directory. It must be absent or empty, otherwise error. There is no `--clobber`. |
| `--bevy-version` | Required, so the script never hardcodes one. Substituted for `{{bevy_version}}`. |
| `--registry` | Optional `downstream-repos.json` in a git checkout. Registered via PR (step 6). Skipped with `--no-remote`. |
| `--workspace` | Optional workspace `Cargo.toml`. For `--lib`, adds the `[patch]` entry (step 7). |
| `--no-remote` | Skip `gh repo create`, `remote add`, `push`, **and** the registry PR, so `.infra` is untouched. |
| `--private` | Visibility for `gh repo create`. **Public is the default.** |
| `-x` | Execute. Dry run is the default. |

**Removed:** `--project/--no-project`, `--create-remote`, `--infra-dir`, `--clobber`,
`$BASE_DIR`, the `.config/` copy, the `.envrc` write, `_sync_repo`, `sync-files.json`,
and `patch_cargo`.

## What `init -x` does

1. **Validate** the name, that `--dest` is empty or absent, and whether the name is
   already in the registry. An existing entry, like today's `q_cam`, is a no-op, not an error.
2. **Render** `assets/project-template/` into `--dest` verbatim. In `src/`, copy **only**
   `lib.rs` (`--lib`) or `main.rs` (`--bin`) and ignore everything else there.
   Replace the exact tokens `{{name}}` and `{{bevy_version}}` in every file. This is
   safe because the template justfile only uses just's spaced `{{ … }}` form.
3. **Verify** from the current directory, which is the org root when run through `just`, with
   `-p NAME`. Reuse `clippy.cmd`, `bevy_lint.cmd`, and `test.cmd`. This is the same as
   `just check -p` / `just test -p`. Nextest gets `--no-tests=pass` because the template has no tests.
   On failure, stop before any git side effects. Don't run from `--dest`: its
   `.cargo/config.toml` would create a second `target/` there.
4. **Git**: `git init -b main`, `add .`, and a signed `commit -m "chore: initial commit"`.
5. **Remote** (unless `--no-remote`): `gh repo create cubething-qproj/NAME --public`,
   `remote add origin`, and `push -u origin main`.
6. **Register** (unless `--no-remote`, or already registered). This never touches your
   `.infra` working tree or current branch:
   - `git fetch origin`, then `git worktree add --force -B automation/init-crate <tmpdir> origin/main`.
     `-B` replaces any stale local branch.
   - Append `cubething-qproj/NAME` to the registry at the same repo-relative path
     inside the worktree. The `downstream-repos.json` symlink is followed to the real file.
   - Signed `commit -m "chore: register NAME"`, `push --force origin automation/init-crate`,
     `gh pr create`, then `git worktree remove`.
7. **Patch** (`--lib` with `--workspace`): add
   `[patch."https://github.com/cubething-qproj/NAME"] NAME = { path = "<dest relative to workspace>" }`
   via tomlkit, if it is missing. This matches the existing entries. Until a sibling depends on the crate,
   Cargo prints a "patch not used" warning. The org root isn't a git repo, so there's nothing to commit.

### Auto-merge the registry PR

Mirror the existing downstream `auto-merge` job:
- in `infra-lint.yml`, add `pull_request` as a trigger;
- add an `auto-merge` job gated on `github.head_ref == 'automation/init-crate'` that runs
  `gh pr merge --merge --delete-branch` with `DISPATCH_TOKEN`.

A PAT merge, unlike `GITHUB_TOKEN`, triggers `infra-sync-downstream` on `main`. That
syncs the new repo, which should be a near no-op apart from generating `flake.lock`.

The force-push in step 6 overwrites an earlier *unmerged* init PR. With auto-merge,
that window is only as long as a lint run.

## Consequences of the tree change

Deleting `config/` and `assets/.config/` breaks `main` as soon as this merges, so these
changes land in the same PR, as separate commits:

- **`infra-sync-downstream.yml`**: replace the `sync-files.json` loop and `patch-cargo` step with
  "copy every template file except `Cargo.toml`, `README.md`, `src/`, `.gitignore`,
  `.zed/settings.json`, and `justfile`, then `sed` `{{bevy_version}}` from `.bevy-version`". Delete `sync-files.json` and
  `.github/templates/`, which the template now duplicates, and update `docs/CI.md`.
- **Delete `patch_cargo.py`** and its CLI verb.
- **Delete `sync`** (see open question 1): `sync.py`, `test_sync.py`, the CLI verb, the
  `sync` recipes in `.infra/justfile` and the template justfile, and the README's bootstrap instructions.

## One-off legacy cleanup (not committed code)

After the PR merges, and after the CI sync has run once, I run a throwaway loop over
the registry's local checkouts. For each repo: `chore/remove-legacy-files` branch,
`git rm -r --ignore-unmatch shared.just scripts/ .config/ AGENTS.md pyrightconfig.json`,
signed commit, push, PR. Remove the obsolete `just sync` recipe from each
existing downstream `justfile` in those same PRs; CI leaves justfiles alone.
I'll show you the list of PRs before pushing. The dangling `AGENTS.md` symlinks
in local `lib/*` checkouts are untracked, so they get a plain `rm`.

## Steps

Stop for review after each step.

1. **`init.py`**: rewrite in place (`_render_project`, `_bootstrap_in_place`, `main`
   stay where they are), plus the root `justfile` wrapper. Tests (`tests/test_init.py`):
   - render a lib into `tmp_path`. Check that the tokens are substituted, only `src/lib.rs` is
     under `src/`, and the justfile's `{{ qproj }}` is untouched;
   - registry append and workspace patch are idempotent;
   - invalid names are rejected.
   Git, `gh`, and cargo are not exercised. Then run `just check` and `just test` in `.infra`,
   plus a real dry run of `just init lib/q_cam`.
2. **Registry PR + auto-merge job.**
3. **CI sync rewrite**, and delete `patch_cargo`, `sync-files.json`, and `.github/templates/`.
4. **Delete `sync`.**
5. **One-off legacy cleanup**, after merge.

Branch: `chore/simplify-init` in `.infra`, created from `origin/main`. Your uncommitted
template and `config/` changes come along, since they don't overlap with `fix/check`.

## Deferred

Member-crate `[profile.*]` blocks are ignored in a workspace, and the root
`Cargo.toml` has none. This remains out of scope.
