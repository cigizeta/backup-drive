# TODO

Loose, running list of outstanding action items -- not full designs (those live in
`active/`/`done/`/`archived/`), just things not to forget.

## Now

- **rewrite-plan.md: code written 2026-11-03 on the development machine.** The real runs happen on
  the machine with the backup disk.
  - **Done on the development machine (2026-11-03):** shellcheck clean; pre-flight failures for
    rclone missing, a bad argument and the marker missing; against temp folders, a dry run, a real
    run, and a second run after a change (new version in `current/`, old one in
    `_versions/<timestamp>/`, one log). The dry run caught a bug: `**/`-prefixed filter rules skip
    top-level files; fixed in `filters.txt` and CLAUDE.md (rules carry no `**/`).
  - **On the machine with the backup disk:** `config.env`, the marker, a dry run, a real run; a
    file changed on Drive and a second run (new version in `current/`, old one in
    `_versions/<timestamp>/`); missing-marker failure; `./schedule.sh install`, `status`, a run
    with `schtasks.exe /Run /TN backup-drive`, `remove`, then `install` for real.
  - Then move rewrite-plan.md to `done/`.
- **Git history:** the House Drive docs in history describe the developer's machines and when one
  is on; whether to rewrite history is open.
