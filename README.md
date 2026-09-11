# agentfiles

Personal coding-agent instructions and skills, shared across harnesses without
duplicating their contents.

## Layout

```text
AGENTS.md                 Base instructions
skills/<name>/SKILL.md    Shared skills
marvin/                   Default agent home, with a persona (see marvin/README.md)
install.sh                Installs prompts and skill links; --uninstall reverses it
SETUP.md                  Agent-driven setup for a new machine
```

`marvin/` is a workspace an agent session runs *in*, not a skill linked into the
harness. Its prompt is tracked; its notes are local to each machine and covered by
deny-by-default rules in `.gitignore`.

Skills keep runtime data — the handoff queue, script state — under
`~/.config/agentfiles/`, never in either repo.

The installer supports Claude Code and Codex:

```text
~/.claude/CLAUDE.md       -> AGENTS.md
~/.claude/skills/<name>   -> skills/<name>
~/.codex/AGENTS.md        -> AGENTS.md
~/.agents/skills/<name>   -> skills/<name>
```

## Private overlays

Instructions that name an employer's repos, teams, or infrastructure don't belong
here. They live in separate private repos of the same shape — an `AGENTS.md`, a
`skills/` directory, or both — installed only on machines that have them:

```bash
./install.sh --overlay ~/projects/<private-repo>
```

The installer remembers each overlay in `~/.config/agentfiles/overlays`, so later runs
need no flags. Each overlay's `AGENTS.md` joins the base prompt for every session, in
the order added, and its `skills/` join the same discovery roots as this repo's.
Skill names must be unique across this repo and every overlay; the installer refuses
to run on a clash. To extend a public skill privately, give the private one its own
name and have the public skill load it, as `tickets` does with a tracker skill.
Tool-specific facts — a tracker's team, IDs, and handles — live in a skill named for
the tool, so they load only when the tool is in use.

With any overlay, the prompt paths become generated files instead of symlinks:

```text
~/.claude/CLAUDE.md       @-imports every AGENTS.md
~/.codex/AGENTS.md        every AGENTS.md concatenated
```

Codex reads a single global file and has no imports, so its copy goes stale: rerun
the installer after editing any `AGENTS.md`. To drop an overlay, uninstall, delete its
line from `~/.config/agentfiles/overlays`, and install again.

Individual skill directories are linked because both harnesses document support
for symlinked skills, while leaving their parent directories available for
harness-managed content.

## Install

On a new machine, ask Claude Code or Codex to set up agentfiles by following
`SETUP.md` in `mcous/agentfiles`. It clones this repo and any private overlays
you name, then runs the installer. Afterward, "update my agent files" pulls both and
relinks through the `agentfiles` skill.

To run the installer by hand, preview changes:

```bash
./install.sh --dry-run
```

Install links for both harnesses:

```bash
./install.sh
```

Existing files are never replaced by default. To move conflicts into a timestamped
directory under `~/.config/agentfiles/backups/` before linking:

```bash
./install.sh --backup
```

Use `--claude` or `--codex` to limit the operation to one harness. The script
is idempotent; rerun it after adding or deleting a skill, and it prunes links to
deleted ones.

## Uninstall

Ask an agent to uninstall agentfiles; the `agentfiles` skill previews the removal
and asks whether to restore backups. By hand:

```bash
./install.sh --uninstall --dry-run            # preview
./install.sh --uninstall --restore            # remove, then restore newest backups
```

That removes the prompts and skill links the installer installed, overlays included,
and nothing else. What remains is `~/.config/agentfiles/`: the handoff queue, script
state, the overlay list, and any backups not restored. Check the queue for unprocessed items before deleting it.

## License

All rights reserved. Published to read and fork from, not yet under an open-source
license.
