#!/usr/bin/env bash
# Copy the files selected by filters.txt from the Google Drive mount to the backup disk.
# Usage: ./backup.sh [--dry-run]
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

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

# Only --dry-run is accepted: no other flag reaches rclone, so nothing can turn the copy into a
# deleting run.
dry_run=
for arg in "$@"; do
  case $arg in
    --dry-run) dry_run=1 ;;
    *) die "usage: ./backup.sh [--dry-run]" ;;
  esac
done

SOURCE_PATH=
DEST_PATH=
load_config "$script_dir/config.env"
[[ -n $SOURCE_PATH ]] || die "config.env: SOURCE_PATH is not set"
[[ -n $DEST_PATH ]] || die "config.env: DEST_PATH is not set"

# A failure stops rather than guesses: never copy into the wrong place.
command -v rclone >/dev/null || die "rclone not found on PATH"
[[ -d $SOURCE_PATH ]] || die "source not found: $SOURCE_PATH (is Google Drive for Desktop running?)"
[[ -n $(find "$SOURCE_PATH" -mindepth 1 -maxdepth 1 -print -quit) ]] ||
  die "source is empty: $SOURCE_PATH (is Google Drive for Desktop signed in?)"
[[ -d $DEST_PATH ]] || die "destination not found: $DEST_PATH (is the backup disk connected?)"
# The marker guards against another disk that Windows gave the same drive letter.
[[ -f $DEST_PATH/.backup-drive ]] ||
  die "marker $DEST_PATH/.backup-drive missing: wrong disk, or create the marker once by hand"
filters=$(cygpath -m "$script_dir/filters.txt")
[[ -f $filters ]] || die "filters not found: $filters"

stamp=$(date +'%Y%m%d-%H%M%S')
# Files replaced by this run are moved to _versions/<stamp> instead of being overwritten, so a
# corrupted or truncated source never destroys the good copy.
args=(
  copy "$SOURCE_PATH" "$DEST_PATH/current"
  --filter-from "$filters"
  --modify-window 2s
  --backup-dir "$DEST_PATH/_versions/$stamp"
)

# A dry run reports to the terminal and leaves no trace on the disk.
if [[ -n $dry_run ]]; then
  exec rclone "${args[@]}" --dry-run
fi

mkdir -p "$DEST_PATH/_logs"
log_file="$DEST_PATH/_logs/backup_$(date +'%Y%m%d').log"
printf '%s backup-drive: start %s\n' "$(date +'%Y/%m/%d %H:%M:%S')" "$stamp" >>"$log_file"
status=0
rclone "${args[@]}" --log-file "$log_file" --log-level INFO || status=$?
printf '%s backup-drive: end %s, exit %d\n' "$(date +'%Y/%m/%d %H:%M:%S')" "$stamp" "$status" \
  >>"$log_file"
if ((status != 0)); then
  printf 'backup-drive: rclone failed with exit %d, see %s\n' "$status" "$log_file" >&2
fi
exit "$status"
