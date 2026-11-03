# backup-drive

Selective local backup of a Google Drive for Desktop mount to an external disk, on Windows with
Git Bash. A standalone `rclone` copies only the files matching `filters.txt` from the virtual
drive (e.g. `G:/My Drive`) to the disk (e.g. `E:/Backup`): no cloud API, no OAuth.

Nothing on the backup disk is ever deleted, and a file that changes on Drive never overwrites its
backup in place: the previous version is moved to `_versions/` first.

## Layout on the backup disk

```text
E:/Backup/
├── .backup-drive          # marker, created once by hand
├── current/               # the backed-up files
├── _versions/<timestamp>/ # files replaced by later runs
└── _logs/backup_YYYYMMDD.log
```

## Setup

1. Install [Git for Windows](https://gitforwindows.org/) and put `rclone.exe` on your `PATH`.
2. Copy the configuration template and edit `SOURCE_PATH`, `DEST_PATH` and `SCHEDULE_TIME`:

   ```bash
   cp config.env.example config.env
   ```

3. Create the marker on the backup disk (with your own `DEST_PATH`). `backup.sh` refuses to run
   without it, so it never writes to another disk that got the same drive letter:

   ```bash
   touch "E:/Backup/.backup-drive"
   ```

4. Edit the includes in `filters.txt`. Rules apply top-down, first match wins, and the file must
   end with `- *`.
5. Check what would be copied:

   ```bash
   ./backup.sh --dry-run
   ```

6. Run it:

   ```bash
   ./backup.sh
   ```

7. Run it daily at `SCHEDULE_TIME` (Task Scheduler, as your user, while you are logged on):

   ```bash
   ./schedule.sh install
   ```

   `./schedule.sh status` shows the last run and its result; `./schedule.sh remove` deletes the
   task.

## Failures

`backup.sh` stops, without copying anything, if `rclone` is missing, the Drive mount is missing
or empty, the backup disk is not connected, or the marker is missing. Those messages go to the
terminal (for a scheduled run, see the last result in `./schedule.sh status`); once a run starts,
everything goes to the day's log in `_logs/`.

## Restoring

Copy the file back from `current/`, or an older version from `_versions/<timestamp>/`, with
Explorer.

## Disk space

`_versions/` only grows. Delete old timestamp folders by hand when you no longer need them.

## License

AGPL-3.0-only, see `LICENSE`.
