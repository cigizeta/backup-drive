# TODO

Loose, running list of outstanding action items -- not full designs (those live in
`active/`/`done/`/`archived/`), just things not to forget.

## Now

- **rewrite-plan.md: code written 2026-11-03 on the development machine.** The real runs happen on
  the machine with the backup disk.
  - **On the development machine:** `shellcheck backup.sh schedule.sh`; the pre-flight failures
    that need no backup disk (bad argument, missing `config.env`, wrong `SOURCE_PATH`, missing
    `DEST_PATH`); `./backup.sh --dry-run` against a test folder with a marker, to check
    `filters.txt` (including the `**/` junk rules at the top level of the source).
  - **On the machine with the backup disk:** `config.env`, the marker, a dry run, a real run; a
    file changed on Drive and a second run (new version in `current/`, old one in
    `_versions/<timestamp>/`); missing-marker failure; `./schedule.sh install`, `status`, a run
    with `schtasks.exe /Run /TN backup-drive`, `remove`, then `install` for real.
  - Then move rewrite-plan.md to `done/`.
- **Git history:** the House Drive docs in history describe the developer's machines and when one
  is on; whether to rewrite history is open.
