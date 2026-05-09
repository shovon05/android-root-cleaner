#!/system/bin/sh
# ============================================================
#  android_cleanup.sh — Full Android Root Cache & Junk Cleaner
#  Usage: su -c "sh /sdcard/android_cleanup.sh"
#  Compatible with: Termux (root) or ADB shell
# ============================================================

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ──────────────────────────────────────────────────
log()     { echo "${CYAN}[INFO]${RESET}  $1"; }
success() { echo "${GREEN}[DONE]${RESET}  $1"; }
warn()    { echo "${YELLOW}[SKIP]${RESET}  $1"; }
error()   { echo "${RED}[ERR] ${RESET}  $1"; }
divider() { echo "${BOLD}──────────────────────────────────────────${RESET}"; }

# ── Human-readable size ──────────────────────────────────────
hr_size() {
    du -sh "$1" 2>/dev/null | awk '{print $1}' || echo "0"
}

# ── Safe delete function ─────────────────────────────────────
safe_delete() {
    local target="$1"
    local label="$2"
    if [ -e "$target" ] || ls "$target" 2>/dev/null | grep -q .; then
        local size
        size=$(du -sh "$target" 2>/dev/null | awk '{print $1}')
        rm -rf "$target" 2>/dev/null
        success "Cleared $label (~${size:-?})"
    else
        warn "$label — nothing to clean"
    fi
}

# ════════════════════════════════════════════════════════════
#  MAIN SCRIPT
# ════════════════════════════════════════════════════════════

divider
echo "${BOLD}   🤖  Android Root Cleanup Script${RESET}"
echo "   $(date)"
divider

# ── Root check ───────────────────────────────────────────────
if [ "$(id -u)" -ne 0 ]; then
    error "Not running as root! Re-run with: su -c 'sh /sdcard/android_cleanup.sh'"
    exit 1
fi

# ── Snapshot: free space before ─────────────────────────────
BEFORE=$(df /data 2>/dev/null | awk 'NR==2{printf "%.1f MB", $4/1024}')
echo "\n${BOLD}💾 Free space before:${RESET} $BEFORE\n"
divider

# ════════════════════════════════════════════════════════════
#  1. APP CACHE (all installed apps)
# ════════════════════════════════════════════════════════════
echo "\n${BOLD}[1] App Cache${RESET}"
safe_delete "/data/data/*/cache/*"       "App caches (/data/data)"
safe_delete "/data/data/*/code_cache/*"  "App code caches"
safe_delete "/data/user/0/*/cache/*"     "User-0 app caches"
safe_delete "/data/user_de/0/*/cache/*"  "Direct-boot app caches"

# ════════════════════════════════════════════════════════════
#  2. DALVIK / ART CACHE
# ════════════════════════════════════════════════════════════
echo "\n${BOLD}[2] Dalvik / ART Cache${RESET}"
safe_delete "/data/dalvik-cache/*"  "Dalvik-ART cache"

# ════════════════════════════════════════════════════════════
#  3. SYSTEM CACHE PARTITION
# ════════════════════════════════════════════════════════════
echo "\n${BOLD}[3] System Cache Partition${RESET}"
safe_delete "/cache/*"  "System cache partition"

# ════════════════════════════════════════════════════════════
#  4. OTA / SYSTEM UPDATE FILES
# ════════════════════════════════════════════════════════════
echo "\n${BOLD}[4] OTA & System Update Files${RESET}"
safe_delete "/data/ota_package/*"           "OTA packages (/data/ota_package)"
safe_delete "/cache/ota/*"                  "OTA cache"
safe_delete "/cache/*.zip"                  "Cached ZIP updates"
safe_delete "/cache/recovery/last_log*"     "Recovery logs"
safe_delete "/cache/recovery/last_kmsg*"    "Recovery kernel messages"
safe_delete "/data/system/theme/*"          "Theme cache"

# ════════════════════════════════════════════════════════════
#  5. EXTERNAL STORAGE CACHE (SD Card / Internal)
# ════════════════════════════════════════════════════════════
echo "\n${BOLD}[5] External / SD Card Cache${RESET}"
safe_delete "/sdcard/Android/data/*/cache/*"  "App caches on SD/internal"
safe_delete "/sdcard/Android/obb/*/cache/*"   "OBB expansion caches"
safe_delete "/sdcard/.thumbnails/*"            "Media thumbnails"
safe_delete "/sdcard/DCIM/.thumbnails/*"       "DCIM thumbnails"

# ════════════════════════════════════════════════════════════
#  6. TEMP & LOG FILES
# ════════════════════════════════════════════════════════════
echo "\n${BOLD}[6] Temp & Log Files${RESET}"
safe_delete "/data/local/tmp/*"   "Local temp files"
safe_delete "/data/log/*"         "System logs (/data/log)"
safe_delete "/data/anr/*"         "ANR traces"
safe_delete "/data/tombstones/*"  "Crash tombstones"
safe_delete "/data/bugreports/*"  "Bug reports"

# ════════════════════════════════════════════════════════════
#  7. ORPHANED APP DATA (uninstalled apps leaving data behind)
# ════════════════════════════════════════════════════════════
echo "\n${BOLD}[7] Orphaned App Data${RESET}"

INSTALLED_PKGS=$(pm list packages 2>/dev/null | sed 's/package://')

count=0
for dir in /data/data/*/; do
    pkg=$(basename "$dir")
    # Skip non-package-looking dirs
    case "$pkg" in
        *.*) ;;   # valid package names contain dots
        *)   continue ;;
    esac
    if ! echo "$INSTALLED_PKGS" | grep -qx "$pkg"; then
        size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
        rm -rf "$dir" 2>/dev/null
        echo "  ${RED}Removed orphan:${RESET} $pkg (~${size:-?})"
        count=$((count + 1))
    fi
done

if [ "$count" -eq 0 ]; then
    warn "No orphaned app data found"
else
    success "Removed $count orphaned app data folders"
fi

# ════════════════════════════════════════════════════════════
#  8. DOWNLOAD TEMP FILES
# ════════════════════════════════════════════════════════════
echo "\n${BOLD}[8] Download Temp Files${RESET}"
safe_delete "/sdcard/Download/*.tmp"       "Temp download files (.tmp)"
safe_delete "/sdcard/Download/*.crdownload" "Incomplete Chrome downloads"
safe_delete "/sdcard/Download/*.part"      "Incomplete part files"

# ════════════════════════════════════════════════════════════
#  DONE — Summary
# ════════════════════════════════════════════════════════════
AFTER=$(df /data 2>/dev/null | awk 'NR==2{printf "%.1f MB", $4/1024}')
divider
echo "\n${BOLD}✅  Cleanup Complete!${RESET}"
echo "  💾 Free space before : $BEFORE"
echo "  💾 Free space after  : $AFTER"
divider
echo "\n${YELLOW}⚡ Tip: Reboot your device for full effect.${RESET}"
echo "    ${CYAN}reboot${RESET}\n"
