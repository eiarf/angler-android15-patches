# Patches & Fixes — Nexus 6P (`angler`) on Android 15 (`lineage-22.2`)

This document tracks all device-tree, kernel, and ROM-level patches identified and verified during bring-up of **DumbOS (`lineage-22.2` / Android 15, `BP1A.250505.005`)** on **Huawei Nexus 6P (`angler`)**.

---

## 1. Device Tree Patches (`device/huawei/angler`) — Universal Across All ROMs

### 1.1 `PhhIms` Missing `READ_PRIVILEGED_PHONE_STATE` Allowlist (Bootloop Fix)
- **Target File:** `configs/permissions/privapp-permissions-me.phh.ims.xml`
- **Symptom:** `system_server` crashes on every boot inside `PackageManagerService.systemReady()` -> `AppIdPermissionPolicy.onSystemReady()` when `ro.control_privapp_permissions=enforce` is enabled (standard in LineageOS/DumbOS):
  ```text
  java.lang.IllegalStateException: Signature|privileged permissions not in privileged permission allowlist: {me.phh.ims (/system/priv-app/PhhIms): android.permission.READ_PRIVILEGED_PHONE_STATE}
  ```
- **Root Cause:** `PhhIms.apk` (`/system/priv-app/PhhIms`) declares both `android.permission.SCHEDULE_EXACT_ALARM` and `android.permission.READ_PRIVILEGED_PHONE_STATE` in its manifest, but `privapp-permissions-me.phh.ims.xml` only allowlisted `SCHEDULE_EXACT_ALARM`.
- **Fix:** Add `<permission name="android.permission.READ_PRIVILEGED_PHONE_STATE"/>` to `configs/permissions/privapp-permissions-me.phh.ims.xml`.
- **Patch File:** `patches/device/0001-angler-Allowlist-READ_PRIVILEGED_PHONE_STATE-for-PhhI.patch`

---

## 2. Kernel Patches (`eiarf/android_kernel_huawei_angler@lineage-22.2`) — Already Applied

### 2.1 Wire Up `sys_renameat2` for 32-Bit Compat Syscalls
- **Commit:** `3f321c4d` (`arm64: compat: Wire up sys_renameat2 for 32-bit compat syscalls`)
- **Target File:** `arch/arm64/include/asm/unistd32.h` (line 789, syscall `382`)
- **Root Cause:** Android 15 Bionic routes `rename()` / `renameat()` through `renameat2()`. Previously, 32-bit compat syscall `382` was stubbed to `sys_ni_syscall` (`ENOSYS`), causing `File.renameTo()` and `SharedPreferencesImpl` atomic backups to fail (e.g., Telegram failing to persist `mainconfig.xml`).
- **Fix:** Wire syscall `382` (`__NR_renameat2`) to `sys_renameat2`.

### 2.2 3.5mm Headset Jack Detection Fix
- **Commit:** `f0ad3a43` (`ASoC: wcd9xxx-mbhc: Do not reject valid headset voltages in CS mode`)
- **Target File:** `sound/soc/codecs/wcd9xxx-mbhc.c`
- **Fix:** Prevents valid headset mic bias voltages from being rejected in CS mode.

---

## 3. ROM / Platform Patches (`DumbOS-ROM@lineage-22.2`) — Universal Across Android 15 Devices

### 3.1 `frameworks/base`: Prevent `fonts.xml` / `font_fallback.xml` Ninja Duplicate
- **Target File:** `frameworks/base/data/fonts/Android.bp`
- **Symptom:** Kati fails with duplicate install target `out/target/product/<device>/system/etc/fonts.xml` and `font_fallback.xml` because Soong emits install rules for AOSP's `prebuilt_etc` modules alongside `vendor/dumbos`'s `PRODUCT_COPY_FILES`.
- **Fix:** Set `installable: false` on `fonts.xml` and `font_fallback.xml` in `frameworks/base/data/fonts/Android.bp` (preserving host/Ravenwood build targets while letting `vendor/dumbos` install its stripped font configs to `/system/etc/`).
- **Patch File:** `patches/frameworks_base/0001-fonts-Disable-installable-on-AOSP-fonts-xml-for-Dumb.patch`

### 3.2 `vendor/partner_gms`: Fix `GmsCore` `zip2zip` Exclusion Glob for Android 15
- **Target File:** `vendor/partner_gms/GmsCore/Android.mk`
- **Symptom:** Build fails on `GmsCore_abi_stripped.apk` with:
  ```text
  zip2zip.go:103: pattern has '**' as last path element
  ```
- **Fix:** Change `zip2zip` exclusion patterns from `'lib/<abi>/**'` to `'lib/<abi>/**/*'`.
- **Patch File:** `patches/vendor_partner_gms/0001-GmsCore-Fix-zip2zip-glob-pattern-for-Android-15.patch`

### 3.3 `vendor/dumbos`: Navigation Mode & Quickstep Availability (Pending User Choice)
- **Target Files:**
  - `vendor/dumbos/apps/DumbLauncher/Android.bp` (`overrides: ["TrebuchetQuickStep", "TrebuchetQuickStepGo"]`)
  - `vendor/dumbos/overlay/frameworks/base/core/res/res/values/config.xml` (`config_navBarInteractionMode`, `config_recentsComponentName`)
- **Symptom:** Gesture/swipe navigation does not work, and the *Navigation mode* menu is hidden in Settings.
- **Root Cause:** `SystemNavigationPreferenceController.isGestureAvailable()` checks `PackageManager.resolveService(Intent("android.intent.action.QUICKSTEP_SERVICE").setPackage(recentsComponentName))`. Because `DumbLauncher` overrides/removes `TrebuchetQuickStep` and `DumbLauncher` does not expose `QUICKSTEP_SERVICE`, `isGestureAvailable()` returns `false` (`UNSUPPORTED_ON_DEVICE`).
- **Fix Options:**
  1. **Enable Gesture + 3-Button Toggle:** Retain `TrebuchetQuickStep` (remove it from `DumbLauncher`'s `overrides`) and restore `config_recentsComponentName` to the Quickstep provider while keeping `DumbLauncher` as the default Home launcher.
  2. **3-Button Only:** Keep `TrebuchetQuickStep` stripped and ensure the 3-button navigation bar overlay is active.
