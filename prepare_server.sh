#!/usr/bin/env bash
set -euo pipefail

# DumbOS (lineage-22.2 / Android 15) — Nexus 6P (angler) Server Setup Script
# Usage: ./prepare_server.sh [WORKDIR]

WORKDIR="${1:-$HOME/dumbos-15-angler}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[1/5] Preparing workspace: $WORKDIR"
mkdir -p "$WORKDIR/.repo/local_manifests"
cd "$WORKDIR"

if [ ! -d ".repo/manifests" ]; then
  echo "[2/5] Initializing DumbOS manifest (lineage-22.2)..."
  repo init -u https://github.com/DumbOS-ROM/android.git -b lineage-22.2 --git-lfs --depth=1
else
  echo "[2/5] Repo already initialized, skipping repo init."
fi

echo "[3/5] Installing local_manifests/angler.xml..."
cp "$SCRIPT_DIR/local_manifests/angler.xml" "$WORKDIR/.repo/local_manifests/angler.xml"

echo "[4/5] Syncing source tree (-j8 to avoid AOSP HTTP 429)..."
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags

echo "[4b/5] Switching hardware/qcom/display to msm8994 donor & setting standalone branches..."
git -C "$WORKDIR/hardware/qcom/display" remote remove msm8994-donor 2>/dev/null || true
git -C "$WORKDIR/hardware/qcom/display" remote add msm8994-donor https://github.com/LineageOS-Nexus-6P/hardware_qcom_display.git
git -C "$WORKDIR/hardware/qcom/display" fetch msm8994-donor lineage-23.0-caf-msm8994
git -C "$WORKDIR/hardware/qcom/display" switch -C lineage-23.0-caf-msm8994 FETCH_HEAD
for r in device/huawei/angler vendor/huawei/angler kernel/huawei/angler packages/apps/PhhIms; do
  git -C "$WORKDIR/$r" checkout -B lineage-22.2
done

echo "[5/5] Fetching nexus6p_patches & running preflight check..."
if [ ! -d "$WORKDIR/nexus6p_patches" ]; then
  git clone -b lineage-22.2 --single-branch \
    https://github.com/LineageOS-Nexus-6P/nexus6p_patches.git \
    "$WORKDIR/nexus6p_patches"
fi

"$WORKDIR/nexus6p_patches/apply.sh" --check --source "$WORKDIR" || {
  echo "WARNING: Some nexus6p_patches conflicted with DumbOS forked repos."
  echo "Inspect the output above and rebase/resolve conflicting patches before building."
  exit 1
}

echo "Preflight clean! Applying nexus6p_patches..."
"$WORKDIR/nexus6p_patches/apply.sh" --source "$WORKDIR"
"$WORKDIR/nexus6p_patches/verify.sh" --source "$WORKDIR"

echo "Ready! Per guideline.md, start with single-module/bootimage test:"
echo "  source build/envsetup.sh && lunch lineage_angler-bp1a-userdebug && mka bootimage"
