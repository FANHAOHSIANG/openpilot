#!/usr/bin/env bash
# Bootstrap branch for installer.comma.ai/FANHAOHSIANG/carrotpilot-dec.
set -euo pipefail
readonly DATA=/data
readonly REPO=https://github.com/FANHAOHSIANG/openpilot-carrot.git
readonly BRANCH=carrotpilot-dec
readonly REQUIRED_COMMIT=ec3451446723cd1da3680a0c49e50a1af20caec2

fail() { echo "Carrot DEC installer: $*" >&2; exit 1; }
offroad() { [[ "$(cat "$DATA/params/d/IsOnroad" 2>/dev/null || true)" != 1 ]]; }
[[ "$(pwd -P)" == "$DATA/openpilot" ]] || fail "Run from /data/openpilot."
offroad || fail "Turn the vehicle off before installing."
exec 9>"$DATA/carrot-dec-install.lock"
flock -n 9 || fail "Another installation is running."
stage=$(mktemp -d "$DATA/carrot-dec-install.XXXXXX")
cleanup() { [[ -z "${stage:-}" ]] || rm -rf -- "$stage"; }
trap cleanup EXIT
echo "Downloading Carrot DEC and parked model switch. Keep Wi-Fi connected."
git clone --progress --branch "$BRANCH" --single-branch --depth 1 --recurse-submodules "$REPO" "$stage"
# Permit future fast-forward updates, but require the integrated feature commit.
if ! git -C "$stage" merge-base --is-ancestor "$REQUIRED_COMMIT" HEAD; then
  git -C "$stage" fetch --unshallow origin "$BRANCH"
  git -C "$stage" merge-base --is-ancestor "$REQUIRED_COMMIT" HEAD || fail "Unexpected source history."
fi
for file in launch_openpilot.sh launch_chffrplus.sh openpilot/selfdrive/controls/lib/carrot_dec.py openpilot/selfdrive/modeld/jetlink/parked.py; do
  [[ -f "$stage/$file" ]] || fail "Missing required file: $file"
done
git -C "$stage" submodule status --recursive > "$stage/.carrot-dec-submodule-status"
if grep -qE '^[-+U]' "$stage/.carrot-dec-submodule-status"; then
  fail "Submodule checkout is incomplete."
fi
rm "$stage/.carrot-dec-submodule-status"
offroad || fail "Vehicle turned on; installation cancelled."
backup=$(mktemp -d "$DATA/carrot-dec-bootstrap.XXXXXX")
rmdir "$backup"
mv "$DATA/openpilot" "$backup"
if ! mv "$stage" "$DATA/openpilot"; then
  mv "$backup" "$DATA/openpilot"
  fail "Could not activate source; bootstrap restored."
fi
stage=
trap - EXIT
cd "$DATA/openpilot"
flock -u 9
exec 9>&-
echo "Carrot DEC downloaded. Starting normal carrotpilot setup."
exec bash ./launch_openpilot.sh
