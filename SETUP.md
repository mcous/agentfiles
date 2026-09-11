# Set up agentfiles on a new machine

Instructions for a coding agent (Claude Code or Codex) that was asked to "set up my
agent files". Work through the steps in order, confirming each with the user before
anything that writes outside the two clones. After setup, updates and relinks go
through the `agentfiles` skill, which this installs.

## 1. Check prerequisites

| Tool | Needed for | Check |
|---|---|---|
| `jj` | Cloning and updating both repos | `jj --version` |
| `gh`, authenticated | Cloning the private repo, marvin's scripts | `gh auth status` |
| `jq` | marvin's scripts | `jq --version` |

Offer to install anything missing with the machine's package manager (`brew` on
macOS). If `gh auth status` fails, ask the user to run `! gh auth login` themselves.

## 2. Clone the public repo

Default location is `~/projects/agentfiles`; ask before using another. If it already
exists, confirm it is this repo and skip to step 3.

```bash
jj git clone --colocate https://github.com/mcous/agentfiles ~/projects/agentfiles
```

## 3. Clone private overlays

Ask whether the user has private overlay repos to load on this machine, and which.
If none, skip to step 4. Clone each beside the public repo:

```bash
jj git clone --colocate git@github.com:<owner>/<repo> ~/projects/<repo>
```

A clone failure means the user's `gh`/SSH identity can't see that repo. Report it;
don't continue without it unless the user says to.

## 4. Install

Follow the Install section of `skills/agentfiles/SKILL.md` from the clone, adding
`--overlay ~/projects/<repo>` for each overlay cloned in step 3. The installer
remembers them, so this is the only run that needs the flag.

## 5. Verify

Tell the user to start a new session so the new prompt and skills load, then check:

- `/skills` (Claude Code) lists `agentfiles`, `tdd`, and `tickets`.
- With overlays, a question only an overlay's prompt answers gets the right answer in
  both harnesses. Ask the user for one rather than guessing.
