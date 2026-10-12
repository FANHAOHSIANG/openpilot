#!/usr/bin/env bash
# Bootstrap branch for installer.comma.ai/FANHAOHSIANG/carrot-wip-map-hud.
set -euo pipefail
readonly DATA=/data
readonly REPO=https://github.com/FANHAOHSIANG/openpilot-carrot.git
readonly BRANCH=carrot-wip-map-hud
readonly REQUIRED_COMMIT=2664c0ddecb16c7228e2d43a85b41d5f52e1f523

fail() { echo "Carrot Map HUD installer: $*" >&2; exit 1; }
offroad() { [[ "$(cat "$DATA/params/d/IsOnroad" 2>/dev/null || true)" != 1 ]]; }
[[ "$(pwd -P)" == "$DATA/openpilot" ]] || fail "Run from /data/openpilot."
offroad || fail "Turn the vehicle off before installing."
exec 9>"$DATA/carrot-map-hud-install.lock"
flock -n 9 || fail "Another installation is running."
stage=$(mktemp -d "$DATA/carrot-map-hud-install.XXXXXX")
cleanup() { [[ -z "${stage:-}" ]] || rm -rf -- "$stage"; }
trap cleanup EXIT
echo "Downloading Carrot Map HUD and CPdazi projection relay. Keep Wi-Fi connected."
git clone --progress --branch "$BRANCH" --single-branch --depth 1 --recurse-submodules "$REPO" "$stage"
# Permit future fast-forward updates, but require the integrated feature commit.
if ! git -C "$stage" merge-base --is-ancestor "$REQUIRED_COMMIT" HEAD; then
  git -C "$stage" fetch --unshallow origin "$BRANCH"
  git -C "$stage" merge-base --is-ancestor "$REQUIRED_COMMIT" HEAD || fail "Unexpected source history."
fi
for file in launch_openpilot.sh launch_chffrplus.sh openpilot/selfdrive/carrot/map_hud.py openpilot/selfdrive/carrot/web/map-hud.html; do
  [[ -f "$stage/$file" ]] || fail "Missing required file: $file"
done
git -C "$stage" submodule status --recursive > "$stage/.carrot-map-hud-submodule-status"
if grep -qE '^[-+U]' "$stage/.carrot-map-hud-submodule-status"; then
  fail "Submodule checkout is incomplete."
fi
rm "$stage/.carrot-map-hud-submodule-status"
offroad || fail "Vehicle turned on; installation cancelled."
backup=$(mktemp -d "$DATA/carrot-map-hud-bootstrap.XXXXXX")
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
echo "Carrot Map HUD downloaded. Starting normal carrotpilot setup."
exec bash ./launch_openpilot.sh
