#!/usr/bin/env bash
# Register, remove or show the daily Task Scheduler task that runs backup.sh.
# Usage: ./schedule.sh install | remove | status
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
task_name=backup-drive

die() {
  printf 'backup-drive: %s\n' "$*" >&2
  exit 1
}

# Reads KEY="value" lines without sourcing the file, so a stray line cannot run anything.
load_config() {
  local file=$1 line key value
  [[ -f $file ]] || die "config not found: $file (copy config.env.example to config.env)"
  while IFS= read -r line || [[ -n $line ]]; do
    line=${line%$'\r'}
    [[ $line =~ ^[[:space:]]*(#|$) ]] && continue
    [[ $line =~ ^([A-Z_]+)=\"(.*)\"$ ]] || die "config.env: cannot parse line: $line"
    key=${BASH_REMATCH[1]}
    value=${BASH_REMATCH[2]}
    case $key in
      SOURCE_PATH | DEST_PATH | SCHEDULE_TIME) printf -v "$key" '%s' "$value" ;;
      *) die "config.env: unknown key: $key" ;;
    esac
  done <"$file"
}

# MSYS_NO_PATHCONV stops Git Bash from rewriting schtasks' /X options as paths.
case ${1:-} in
  install)
    SCHEDULE_TIME=
    load_config "$script_dir/config.env"
    [[ $SCHEDULE_TIME =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]] ||
      die "config.env: SCHEDULE_TIME must be HH:MM (24-hour), got: '$SCHEDULE_TIME'"
    bash_exe=$(cygpath -w "$(command -v bash)")
    backup_sh=$(cygpath -w "$script_dir/backup.sh")
    # No /RU: the task runs as the logged-on user, only while logged on, because the Google
    # Drive mount exists only in that user's session.
    MSYS_NO_PATHCONV=1 schtasks.exe /Create /F /TN "$task_name" /SC DAILY /ST "$SCHEDULE_TIME" \
      /TR "\"$bash_exe\" -l \"$backup_sh\""
    ;;
  remove)
    MSYS_NO_PATHCONV=1 schtasks.exe /Delete /F /TN "$task_name"
    ;;
  status)
    MSYS_NO_PATHCONV=1 schtasks.exe /Query /TN "$task_name" /V /FO LIST
    ;;
  *)
    die "usage: ./schedule.sh install | remove | status"
    ;;
esac
