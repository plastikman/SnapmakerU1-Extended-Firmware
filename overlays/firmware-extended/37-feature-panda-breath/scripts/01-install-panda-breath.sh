#!/usr/bin/env bash

GIT_URL=https://github.com/plastikman/pandabreath-klipper.git
GIT_SHA=be56938a2e65836daede87444070a63af060da35

if [[ -z "$CREATE_FIRMWARE" ]]; then
  echo "Error: This script should be run within the create_firmware.sh environment."
  exit 1
fi

set -eo pipefail

TARGET_DIR="$CACHE_DIR/pandabreath-klipper"
LAVA_UID=1000
LAVA_GID=1000

cache_git.sh "$TARGET_DIR" "$GIT_URL" "$GIT_SHA"

echo ">> Installing Panda Breath Klipper extras..."
install -Dm644 -o "$LAVA_UID" -g "$LAVA_GID" "$TARGET_DIR/panda_breath.py" \
  "$ROOTFS_DIR/home/lava/klipper/klippy/extras/panda_breath.py"

# ── LOCAL 70C ENABLE (personal build — do NOT upstream) ───────────────────────
# Raise the stock-mqtt target clamp 60C -> 70C so M141/M191 can command 70C over
# MQTT. Requires the Panda device firmware to be 70C-patched
# (tools/patch_panda_breath_70c.py) AND adequate MCU/enclosure cooling — which is
# why this stays a personal build tweak, not the shipped default. Fails the build
# loudly if the upstream clamp string ever changes.
_PB_EXTRA="$ROOTFS_DIR/home/lava/klipper/klippy/extras/panda_breath.py"
echo ">> [local] Raising stock-mqtt target clamp 60C -> 70C..."
sed -i 's/min(60, int(round(degrees)))/min(70, int(round(degrees)))/' "$_PB_EXTRA"
grep -q 'min(70, int(round(degrees)))' "$_PB_EXTRA" \
  || { echo "ERROR: 70C clamp patch did not apply (upstream clamp string changed)"; exit 1; }

echo ">> Panda Breath installation completed successfully."
