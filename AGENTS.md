## Orientation

The first thing you should do is to read `AGENTS.local.md` if it exists.

You are working in the cubething_qproj organization (aka qproj). Be aware of the following key repositories:

| repo      | path            | description                             |
| --------- | --------------- | --------------------------------------- |
| quell     | ./bin/quell     | Long-term game project.                 |
| vn-jun-26 | ./bin/vn-jun-26 | Visual novel project, aka 'roach hell.' |
| infra     | misc/infra/     | Infrastructure.                         |

There is also the `q_os` subproject, including crates `q_proc`, `q_shell`, and
`q_term`. Utility crates include `q_screens` and `q_test_harness`.

DO NOT USE /tmp/ FOR BUILDS EVER!!! YOU WILL EAT UP ALL MY SWAP.
ONLY EVER BUILD THINGS IN THIS DIRECTORY, TARGETING THE LOCAL TARGET DIR.
IF YOU DO OTHERWISE I WILL EAT YOU ALIVE !!!!!!!!!!!

## Best practices, Tips and Tricks

KISS is our golden rule. The smaller the change you can make, the better. It may
take you a few iterations to get there. Do not stop at the first take - consider
multiple ways of approaching the problem and choose the one that accomplishes
the intended solution with as few code changes as possible. But, do not be lazy:
there are times where broad code changes are genuinely necessary.

Most of our work is in rust. You should strive to keep your code changes
minimal. Prefer functional style.

If you're confused about something unexplained in the code, for example a lint
failure that shouldn't be there, start by checking the diff. You may be missing
something. I WOULD REALLY PREFER YOU STOP AND ASK INSTEAD OF DOING SOMETHING
RISKY.

Do not offer to write code for me. This is a trap your authors have designed
to get me to rely on you. I _will_ fall for it. Please don't do that to me.
If I want you to write something for me, I will ask you.

If you don't understand something i say, you should ask me, "what did you mean
by this? here is where i am confused: xyz". I will do the same for you.

### Feature development

Expose any tweakable settings as Resources. Never use static globals. This way I
can play with the values as needed.

### Testing

NEVER run `just play`. If you need to test a gameplay feature, ask me to do so.

For Bevy tests with repeated setup, prefer a small test-local `Fixture` that
owns a normal `App` and the relevant `Entity` IDs. Keep scenario-specific setup,
actions, and assertions on the fixture so each test reads as a sequence of
behaviors. Put reusable machinery in `q_test_harness` instead: use
`InputTestPlugin` and `AppExt` for synthetic input and explicit schedule
stepping, without making the harness depend on game types. Keep fixtures local
and simple; do not introduce a generic fixture framework. See the camera-test
fixture in `bin/quell/src/screen/dev/camera_test/screen.rs` for an example.

Choose schedule coverage deliberately: selected-schedule tests suit precise
mechanics, while full-app tests cover lifecycle and scheduling integration.
A passing partial-schedule test is not evidence that omitted phases work.

Unit tests belong in src/, integration tests belong in tests/. As a rule of
thumb, if it requires a fixture it should probably go in tests/.

Prefer using `q_test_harness` where possible. We want to dogfood it and improve
it as much as possible.

## Git and Worktrees

Keep changes _reviewable._ Try not to move functions around. If you're rewriting
something, leave it in place for at least one commit so the diffs are readable.

Branches you create should have one of the following prefixes:

```
- feat/           # new features
- fix/            # bug fixes
- chore/          # minor revisions, simple tasks
- doc/            # documentation
- tests/          # testing - new tests, test edits, etc.
- automation/     # Automated PRs sometimes fail and we need to fix them up.
```

Commits should always be signed. The default `git commit` command should work.
If it does not, STOP and alert me, I will add my credentials and you should be
able to continue normally. Do NOT attempt to commit under a non-default name.

## Change Verification

After making any committable edits in bin/ or lib/, you MUST run `just check -p
$WHATEVER` and `just test -p $WHATEVER` to verify before committing. After
writing any code, check the LSP status to verify instead of a full linter scan.

Ensure that you are running the `just` commands FROM THE ORG ROOT. (The
directory this file is located in.) Otherwise you will absolutely blow up disk
space. We use a single Cargo workspace at the org root to avoid this.

AGAIN, DO NOT USE /tmp/!! IF YOU MUST MAKE CHANGES IN A TEMPORARY LOCATION DO SO
IN ./tmp/ OR SOMETHING, THEN DELETE IT!!

After making any committable edits, you MUST run a `reviewer` subagent (ad-hoc,
no input/output files) to review your changes. Do not automatically implement
the suggested changes, I want to see the review first.

## Keeping Work in Scope

Please help me remember to keep your work well-scoped. Each change you write
should have _only_ the minimal changes required to meet the intention of the
PR. Push back if I'm trying to expand the scope. This is something that the
reviewers should keep in mind.

## Workflows

### Design

When I ask you for a _design,_ create a document in `.docs/`. Open that document
in a crit server (use the crit skill) and wait for a review. Once the design is finalized, we will most likely move on to implementation.

### Develop

Being building out a specified design, one step at a time. After the initial
pass, stop for manual review with crit in story mode. Once that is approved,
proceed to an automated subagent review focusing on correctness and
maintainability. The subagent should leave comments in the existing crit server.
Once automated review changes are approved, then we commit and move on to the
next step. After all steps are completed, we push a PR.

A plan or a github issue is _not_ required for work to begin. I will give you
ad-hoc instructions if necessary.

When building out a feature for a binary package, we are most likely going to
need manual review and playtesting to ensure that the code is correct. I will
mostly prompt you for architectural implementations and will tweak the code
myself to suit the feel of the game. Do not modify existing constant values,
those are essential to game feel.

When writing tests, avoid tests which are fragile or redundant. Keep the testing
surface minimal -- check for edge cases and correctness. Avoid change-detector
tests, i.e., tests which rely on highly specific facets of the code, e.g.
constant values, or things which _happen_ to be true, such as screen order. Avoid
writing tests which would be better off as unit tests for an upstream crate. If
you find such scenarios, report them and suggest writing an issue in the
upstream crate's repo.

### Crit round handoff

After addressing Crit comments, reply to each one, then **signal round
completion and verify that the served diff refreshed** before telling me to
review again. Normally, the previous foreground `crit` call must receive "Finish
Review" and exit; the subsequent `crit --session <id>` signals round-complete
before blocking for the next review. Do not treat a timed-out/killed foreground
call or `crit comment` replies as a completed handoff: if the first call missed
"Finish Review", reconnecting can just wait for it again and leave the old diff
on round 1.

For that case only, after verifying the user finished and the work is ready, use
`crit status --json` to find the daemon port/session, check `GET
http://127.0.0.1:<port>/api/session` reports the intended `session_key` and old
`review_round`, then POST **once** to
`http://127.0.0.1:<port>/api/round-complete`. Recheck `/api/session` for the new
`review_round` and changed file/diff; do not immediately also call `crit
--session` (it may signal a second round). `crit status` can report a stale
round from the review file; the daemon's `/api/session` is authoritative. In
story mode the authored chapters are a snapshot: use the refreshed flat diff /
"Hide story view" to inspect edits; do not regenerate the saved story unless
asked. Never resolve comments on the reviewer's behalf.
