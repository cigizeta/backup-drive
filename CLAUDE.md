# CLAUDE.md -- backup-drive

`backup-drive` is an automated, local-to-local selective backup utility for Windows systems running
Git Bash. It uses a standalone `rclone` binary to copy high-priority files (matching glob/filter
patterns) from a Google Drive for Desktop virtual mount (e.g., `G:/My Drive`) to an external local
hard drive (e.g., `E:/Backup`), bypassing cloud API quotas and authentication flows.

## Never leak secrets or sensitive information

This repository is public: everything committed is visible to anyone, forever, history included.
**Never write**, to any file, commit message, issue, pull request, published page or external
service:

- **Secrets:** passwords, tokens, keys, credentials of any kind, even expired or fake-looking ones.
- **Identifying details:** hostnames, IP addresses, MAC addresses, user names, e-mail addresses,
  share names, paths on a real machine, serial numbers.
- **Personal or household information:** schedules, habits, travel, when a home is empty or a
  machine is off, where anyone works or lives.

Real values live only in the gitignored `config.env`; the repository holds `config.env.example`
with placeholders. Examples in code, tests and docs use generic names (`G:/My Drive`,
`E:/Backup`, `C:\example\data`). Before writing a file the developer may commit, check it for any
of the above; when in doubt, leave it out and ask. A leak already committed cannot be fixed by a
later commit: say so at once, so the developer can rewrite history and rotate the secret.

## No autonomous writes allowed

The development of this project assumes that access to NotebookEdit, Bash,
and Monitor are fully denied to Claude. As a consequence, Git is also
fully denied.

## claude/ organization

`claude/` (prose, distinct from the `.claude/` harness config) holds `TODO.md` plus `active/`,
`done/`, and `archived/`.

- `active/`: work in progress.
- `done/`: completed, verified work, moved from `active/` as-is, no rename.
- `archived/`: superseded/abandoned/stale docs, moved here as-is with
  a "superseded, see X" note if applicable.

Source code must never reference a `claude/` document (bare filename or
path) -- inline the "why" directly in the code instead.

Within `claude/`, docs may reference each other, but only by bare filename,
because filenames survive moves between the three subdirectories; paths do not.

## Design first, implement later

Do not rush off implementing. First discuss the design thoroughly, then write
the implementation plan as a document in `claude/active/`, and only then apply
it.

## Fenced blocks

When you want the developers to run something themselves, such as shell
commands or a commit, put it inside a fenced block so that they can copy it.
Put each command in its own fenced block: three consecutive commands are
three fenced blocks, never one block holding all three. Commit messages
must be one line only.

## Repository structure

```text
backup-drive/
├── backup.sh             # Main orchestration shell script
├── filters.txt           # Rclone include/exclude pattern rules
├── config.env.example    # Configuration template for local paths and options
├── config.env            # User configuration (untracked)
├── .gitignore            # Git exclusion rules
├── README.md             # Project documentation and setup guide
└── CLAUDE.md             # AI assistant guidance and project conventions
```

## Key architectural principles

1. **Local-to-local operation:** No cloud API remotes or OAuth authentication keys are used.
   `rclone` treats both the Google Drive virtual drive and the backup HDD as local filesystem
   targets.
2. **Deterministic filter precedence:** Rclone evaluates filter rules sequentially top-down. The
   first rule matching a path wins. The filter file MUST terminate with `- *` to enforce selective
   inclusion.
3. **Idempotence and safety:**
   - The backup uses `rclone copy` rather than `rclone sync` to prevent accidental deletions on the
     local backup disk if files are deleted or moved on Google Drive.
   - Timestamps and sizes are preserved. `--modify-window 2s` is used to prevent false positives
     across FAT32/NTFS boundary quirks.

## Safety first

The backup disk holds the only second copy of the user's files. Nothing on it is ever deleted or
overwritten by a newer-looking but smaller or broken source without that being an explicit,
reviewed choice: never switch `copy` to `sync`, and never add `--delete-*` flags casually. A
failure stops rather than guesses: a missing source mount or destination drive aborts the run
instead of copying into the wrong place.

## Development platform: Windows only

backup-drive is developed, tested and run on native Windows only, not WSL, and Linux is not a
target. The shell is **Git Bash**, never PowerShell or cmd: every command in a fenced block uses
Bash syntax.

- Line endings are governed by `.gitattributes`: Bash scripts always LF, Windows scripts always CRLF,
  every other text file stored LF and checked out with the OS's native endings.
- Git Bash rewrites arguments that look like Unix paths when calling native Windows programs; prefix
  the command with `MSYS_NO_PATHCONV=1` when that bites.

### Dependencies

- Git for Windows (providing Git Bash / MSYS2 environment).
- `rclone.exe` accessible in `$PATH`.
- `shellcheck` (recommended for script validation).

### Common commands

- **Lint Bash scripts:**
  ```bash
  shellcheck backup.sh
  ```

- **Dry-run verification (testing filters without copying):**
  ```bash
  rclone copy "$SOURCE_PATH" "$DEST_PATH" --filter-from filters.txt --dry-run
  ```

- **Run manual backup execution:**
  ```bash
  ./backup.sh
  ```

- **View latest log output:**
  ```bash
  tail -n 50 "$DEST_PATH/_logs/backup_$(date +'%Y%m%d').log"
  ```

## Coding and script conventions

- **Shell standard:** Write scripts targeting `bash` (Git Bash on Windows).
- **Strict mode:** Always enforce `set -euo pipefail` at the start of bash scripts.
- **Path compatibility:**
  - Prefer forward-slash absolute paths for Windows drives (e.g., `G:/My Drive`, `E:/Backup`).
    These work cleanly across both Git Bash and the native `rclone.exe` binary.
  - Quote all path variables to handle spaces in folder names.
- **Environment separation:** Never commit hardcoded machine-specific drive letters or paths to
  version control. Load path parameters exclusively through `config.env`.
- **Rclone filter syntax:**
  - Prefix includes with `+ ` and excludes with `- `.
  - Prefix directory-recursive rules with `**/` (e.g., `+ **/*.kdbx`).
  - Keep exclusion of OS junk (`Thumbs.db`, `.DS_Store`, `$RECYCLE.BIN`, `.git`) explicit before
    the final catch-all exclude (`- *`).

## Licensing

backup-drive is AGPLv3 only (`LICENSE`, `AGPL-3.0-only`).

## No em dashes

Never write em dashes or en dashes to any file in this repository, Markdown or otherwise. Write a
double hyphen (--) instead. Ordinary hyphens (-) are fine.
