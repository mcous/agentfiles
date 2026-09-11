---
name: agentfiles
description: Install, update, relink, or uninstall Michael's shared base prompt and skills for Claude Code and Codex. Use when asked to update or pull agentfiles, repair its links, add newly authored skills to harness discovery paths, refresh the prompt after editing either AGENTS.md, or explicitly invoked. For a machine with no clone yet, follow SETUP.md in mcous/agentfiles instead.
---

# Agentfiles

The public repo is `~/projects/agentfiles`. Private overlay repos, if any, are listed
one path per line in `~/.config/agentfiles/overlays`; the installer reads that list
itself.

## Update

Only when asked to update or pull. For the public repo and each overlay:

1. `jj -R <repo> git fetch`.
2. If `main` is conflicted or has diverged from `main@origin`, stop and report it.
3. `jj -R <repo> rebase -b @ -d main`, carrying any working-copy edits onto the new
   `main`. Report conflicts rather than resolving them.

Then install.

## Install

`install.sh` in the public repo is the deterministic implementation.

1. Run `./install.sh --dry-run`.
2. If there are no conflicts, rerun without `--dry-run`.
3. If conflicts exist, report their paths and ask before running with `--backup`.
   Backups go under `~/.config/agentfiles/backups/<timestamp>/`.
4. Use `--claude` or `--codex` when the user limits the request to one harness.
5. Report the links created and any backup directory used.

Do not delete or overwrite conflicting configuration manually. The script is
idempotent; rerun it after adding or deleting a skill, and, with overlays, after
editing any `AGENTS.md`. Pass `--overlay <repo>` only to add a new overlay.

## Uninstall

1. Run `./install.sh --uninstall --restore --dry-run` and show the user what would be
   removed and which backups would come back.
2. Ask whether to restore them. Run `./install.sh --uninstall --restore` on yes,
   `./install.sh --uninstall` on no.
3. Report what remains in `~/.config/agentfiles/`, including any unprocessed handoffs,
   and ask before deleting it.
