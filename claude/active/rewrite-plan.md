# Rewrite plan: from House Drive to the rclone selective backup

Status: approved and written 2026-11-03 on the development machine; verification pending, the
real runs on the machine with the backup disk (see TODO.md). Started 2026-11-03.

CLAUDE.md now describes a Bash + rclone selective backup. The repository still holds the Rust
House Drive workspace, which is obsolete. This plan replaces it.

## Decisions (2026-11-03)

1. **Old versions are kept:** replaced files go to `_versions/<timestamp>/` through
   `--backup-dir`, never overwritten in place. Pruning stays manual.
2. **Marker file required:** `backup.sh` refuses to run unless `DEST_PATH/.backup-drive` exists,
   so a different disk that got the same drive letter is never written to.
3. **Scheduling included,** delivered as a `schedule.sh` script around `schtasks.exe`; the run
   time lives only in `config.env`.
4. **Layout on the backup disk:**

   ```text
   E:/Backup/
   ├── .backup-drive          # marker, created once by hand
   ├── current/               # the backed-up files
   ├── _versions/<timestamp>/ # files replaced by later runs
   └── _logs/backup_YYYYMMDD.log
   ```

## Files

### `config.env.example`

```bash
SOURCE_PATH="G:/My Drive"
DEST_PATH="E:/Backup"
SCHEDULE_TIME="HH:MM"
```

`backup.sh` and `schedule.sh` parse it line by line, accepting only these keys (`KEY="value"`,
comments and blank lines), and never `source` it, so a stray line cannot run anything. A missing
or empty required key stops the script. `SCHEDULE_TIME` is required only by `schedule.sh`.

### `backup.sh`

`set -euo pipefail`. Usage: `./backup.sh [--dry-run]`; any other argument is an error (no
pass-through, so no `--delete-*` or `sync`-like flag can slip in).

1. Locate `config.env` and `filters.txt` next to the script (not the current directory), so the
   scheduled run finds them.
2. Load the config.
3. Pre-flight, each failure printing one clear line to stderr and exiting non-zero:
   - `rclone` not on `PATH`;
   - `SOURCE_PATH` missing, or empty (Drive for Desktop not running or not mounted);
   - `DEST_PATH` missing (disk not connected);
   - `DEST_PATH/.backup-drive` missing (wrong disk, or setup not done).
   These run before any log file exists on the disk, so they go to stderr only; for a scheduled
   run, Task Scheduler's last result shows the failure.
4. Run:

   ```bash
   rclone copy "$SOURCE_PATH" "$DEST_PATH/current" \
     --filter-from "$script_dir/filters.txt" \
     --modify-window 2s \
     --backup-dir "$DEST_PATH/_versions/$stamp" \
     --log-file "$DEST_PATH/_logs/backup_$(date +'%Y%m%d').log" \
     --log-level INFO \
     ${dry_run:+--dry-run}
   ```

   `$stamp` is `YYYYMMDD-HHMMSS`. rclone creates `_versions/$stamp` only when it moves something,
   so unchanged runs leave no empty folders. A start and end line with the exit code are appended
   to the same log.
5. Exit with rclone's exit code.

### `filters.txt`

Generic, commit-safe patterns: a few `+ **/*.<ext>` includes (e.g. `*.kdbx`, office documents,
PDFs) as examples to edit, then the explicit junk excludes (`Thumbs.db`, `.DS_Store`,
`$RECYCLE.BIN/**`, `.git/**`) placed before the includes so junk never matches an include, and
`- *` last. Comments explain first-match-wins.

### `schedule.sh`

`set -euo pipefail`. Usage: `./schedule.sh install | remove | status`.

- `install`: reads `SCHEDULE_TIME`, validates `HH:MM`, and registers a daily task named
  `backup-drive` with `schtasks.exe /Create /F /SC DAILY /ST <time>`, running Git Bash's
  `bash.exe` (path from `cygpath -w "$(command -v bash)"`) on `backup.sh` (path from
  `cygpath -w`). The task runs as the logged-on user only, because the Google Drive mount exists
  only in that user's session. `MSYS_NO_PATHCONV=1` around `schtasks.exe`, whose `/X` options
  Git Bash would otherwise rewrite.
- `remove`: `schtasks.exe /Delete /F /TN backup-drive`.
- `status`: `schtasks.exe /Query /TN backup-drive /V /FO LIST`, showing the last run time and
  last result.

### Other files

- `.gitignore`: drop the Cargo rules; ignore `config.env`.
- `README.md`: what it does, the layout above, setup (install rclone, copy the config template,
  create the marker, edit filters, dry run, real run, `schedule.sh install`), restoring a file
  from `current/` or `_versions/`, and pruning `_versions/` by hand.
- `CLAUDE.md`: add `schedule.sh` to the repository structure; describe `current/`, `_versions/`
  and the marker under the architectural principles.
- `claude/`: retire the House Drive docs; rewrite `TODO.md` around this plan.

## Removals (by the developer; Claude has no Bash or Git)

`crates/`, `examples/`, `Cargo.toml`, `Cargo.lock`, and the untracked `target/`.

## Verification

1. `shellcheck backup.sh schedule.sh` clean.
2. Each pre-flight failure triggered once (wrong source, missing disk, missing marker, bad
   argument), each with its message and a non-zero exit.
3. `./backup.sh --dry-run` lists the expected files only.
4. A real run, then a file changed on Drive and a second run: the new version in `current/`, the
   old one in `_versions/<timestamp>/`.
5. `./schedule.sh install`, `status`, a run triggered with `schtasks.exe /Run`, then `remove`.
