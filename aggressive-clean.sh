#!/system/bin/sh

su -c '
pm trim-caches 999G
find /data/data/*/cache -type f -delete 2>/dev/null
find /data/user/0/*/cache -type f -delete 2>/dev/null
rm -rf /data/local/tmp/*
rm -rf /cache/*
rm -rf /sdcard/DCIM/.thumbnails/*
find /data/log -type f -delete 2>/dev/null
rm -rf /data/ota_package/* 2>/dev/null
rm -rf /cache/recovery/* 2>/dev/null
rm -rf /data/dalvik-cache/*
sync
reboot
'
