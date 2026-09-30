# Jackdaw documentation snapshot

A vendored, read-only copy of Jackdaw's docs, kept here so that neither agents
nor people need to re-download them. Don't edit these files. To update them,
re-snapshot (see below).

- **Source:** https://github.com/jbuehler23/jackdaw
- **Commit:** `ae948e4c92a9350991edec8f0d6c7539cac0c1f4` (2026-09-28T21:44:37+01:00)
- **Online:** https://jbuehler23.github.io/jackdaw/introduction.html · API: https://docs.rs/jackdaw
- **License:** MIT OR Apache-2.0 (the upstream repo's `LICENSE-MIT` / `LICENSE-APACHE`)

| Path | Upstream | Notes |
| --- | --- | --- |
| `book/` | `book/src/` | The mdBook source; `SUMMARY.md` is the table of contents |
| `templates/game/` | `templates/game/` | The canonical game project `jd new` scaffolds |
| `examples/*.rs` | `examples/*.rs` | Runnable examples. `examples/assets/` (3.3 MB of binaries) is omitted. |
| `examples/extension/` | `examples/extension/` | Sources only. `Cargo.toml` files are renamed `Cargo.toml.example` so tools don't treat them as projects. |

## Refreshing

Snapshot into the org root's `./tmp/`, never `/tmp`, then replace this folder's
contents and update the commit above:

```sh
mkdir -p tmp && git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/jbuehler23/jackdaw.git tmp/jackdaw
git -C tmp/jackdaw sparse-checkout set book templates/game examples
git -C tmp/jackdaw log -1 --format='%H %cI'
```

Then:

1. Copy `book/src`, `templates/game`, `examples/*.rs`, and
   `examples/extension/**/{*.rs,*.md}` here.
2. Rename the extension `Cargo.toml` files to `Cargo.toml.example`.
3. Delete `tmp/jackdaw`.
