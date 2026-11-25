# CHECKPOINT — angler (DumbOS / lineage-22.2 Android 15)

- **Tanggal/Waktu:** 2026-11-25 11:26 WIB (Full Build `mka bacon` Selesai)
- **Build ID / Artifact Terakhir:** `DumbOS-22.2-20261125-UNOFFICIAL-angler.zip` (`926,435,699` bytes, SHA-256: `0d39868821ee5552157399d0b07d094dd46048ee78084d7c5a2c31f35ff8339b`)
- **Platform Base:** `DumbOS-ROM/android@lineage-22.2` (`BUILD_ID=BP1A.250505.005`)
- **Device Tree:** `LineageOS-Nexus-6P/android_device_huawei_angler@lineage-22.2`
- **Vendor Blobs:** `LineageOS-Nexus-6P/android_vendor_huawei_angler@lineage-22.2`
- **Kernel:** `eiarf/android_kernel_huawei_angler@lineage-22.2` (Linux 3.10, `angler_defconfig` + `CONFIG_RT_GROUP_SCHED=n`) | **SELinux:** Enforcing (default device tree, verifikasi saat Fase 2)
- **Batas Partisi:**
  - `boot` <= `33554432` bytes (32 MiB)
  - `recovery` <= `33554432` bytes (32 MiB)
  - `system` <= `3221225472` bytes (3072 MiB / 3 GiB, ext4, journal 0)
  - `vendor` <= `209715200` bytes (200 MiB, squashfs lz4)
  - `cache` <= `104857600` bytes (100 MiB, ext4)

## 1. Do Not Break List (Target Verifikasi Bring-Up)
- [ ] Boot & ADB stabil (`sys.boot_completed=1`, 0 kernel panic / SLUB corruption)
- [ ] Syscall `renameat2` (32-bit compat syscall 382) aktif & Telegram/SharedPreferences tersimpan permanen
- [ ] Display & Touch (`1440x2560`, HWC2/Gralloc1)
- [ ] Audio Speaker & 3.5mm Jack (`wcd9xxx-mbhc` CS mode fix)
- [ ] DumbOS UX (`DumbLauncher`, Monochrome SystemUI, `microG`, custom fonts)
- [ ] Thermal / CPU / GPU / ZRAM (`CONFIG_ZRAM=y`, `CONFIG_ZRAM_LZ4_COMPRESS=y`)
- [ ] RIL / Modem / Wi-Fi (`bcmdhd`) / Bluetooth (`BCM4358`) / GNSS / SensorHub (`nanohub`) / Camera

## 2. Daftar Patch Aktif (Synced & Idempotent)
- **Kernel (`eiarf/android_kernel_huawei_angler@lineage-22.2`):**
  - `3f321c4d` — `arm64: compat: Wire up sys_renameat2 for 32-bit compat syscalls` (mengubah stub `sys_ni_syscall` menjadi `sys_renameat2` di `arch/arm64/include/asm/unistd32.h:789`)
  - `f0ad3a43` — `ASoC: wcd9xxx-mbhc: Do not reject valid headset voltages in CS mode` (fix deteksi jack 3.5mm di `sound/soc/codecs/wcd9xxx-mbhc.c`)
- **Platform (`LineageOS-Nexus-6P/nexus6p_patches@lineage-22.2`):**
  - Seluruh 19 series patch platform diterapkan bersih & lolos `verify.sh` (30/30 test OK).
- **DumbOS (`patches/frameworks_base/` & `patches/vendor_partner_gms/`):**
  - `0001-fonts-Disable-installable-on-AOSP-fonts-xml-for-Dumb.patch` — Menyetel `installable: false` pada `fonts.xml` dan `font_fallback.xml` di `frameworks/base/data/fonts/Android.bp` agar tidak bentrok dengan `PRODUCT_COPY_FILES` font milik `vendor/dumbos`.
  - `0001-GmsCore-Fix-zip2zip-glob-pattern-for-Android-15.patch` — Mengubah pola `zip2zip` di `vendor/partner_gms/GmsCore/Android.mk` dari `/**` menjadi `/**/*` agar kompatibel dengan `zip2zip` Android 15.

## 3. Issue Terbuka / Keterbatasan Diketahui
- Build `.zip` sudah selesai, belum diuji flash/boot di perangkat fisik Nexus 6P (verifikasi live `Do Not Break List` menyusul saat perangkat tersedia).
- `CONFIG_SLUB_DEBUG` tidak aktif di `angler_defconfig` (sesuai rekomendasi produksi DumbOS; aktifkan sementara hanya jika terjadi korupsi SLUB saat bring-up).

## 4. Hipotesis yang Sudah Digugurkan (Ruled-Out)
- *Overriding `fonts.xml`/`font_fallback.xml` via `prebuilt_etc` `overrides` di `vendor/dumbos/prebuilt/Android.bp`:* DIGUGURKAN. `installs-lineage_angler.mk` tetap meng-emit target install AOSP sehingga bentrok di Kati; solusinya adalah `installable: false` di `frameworks/base/data/fonts/Android.bp` (tetap menjaga target host/ravenwood).

## 5. Bukti Audit Terakhir
- **Audit Full Build `mka bacon` (2026-11-25, `19:14`):**
  - `DumbOS-22.2-20261125-UNOFFICIAL-angler.zip`: `926,435,699` bytes (~884 MiB), SHA-256: `0d39868821ee5552157399d0b07d094dd46048ee78084d7c5a2c31f35ff8339b`
  - `boot.img`: `12,980,224` bytes (`38.68%` dari `33,554,432` bytes), SHA-256: `80052949c712c41b526e0496796d75a6c724fdf55596ba24f69120de45ae7e26`
  - `recovery.img`: `24,571,904` bytes (`73.23%` dari `33,554,432` bytes), SHA-256: `3d92aea9dd0cb1f8c813ef66f6ade41a8e1217303eb4d995c5fca2c78377bd76`
  - `system.img`: `1,716,318,752` bytes (`53.28%` dari `3,221,225,472` bytes)
  - `vendor.img`: `163,672,156` bytes (`78.04%` dari `209,715,200` bytes)
  - `nexus6p_patches/verify.sh` lulus `30/30` test.
  - `eiarf/android_kernel_huawei_angler@lineage-22.2` sudah memuat commit `3f321c4d` (`sys_renameat2` 32-bit compat) dan `f0ad3a43` (`wcd9xxx-mbhc` 3.5mm jack).
