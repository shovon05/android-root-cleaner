# Android Root Cleaner

Minimal Android cleanup scripts for rooted devices.

## Features

- Clear app cache
- Remove temporary files
- Delete thumbnail cache
- Clean OTA leftovers
- Remove logs
- Optional Dalvik cache cleanup

## Requirements

- Root access
- Termux or any shell with `su`

## Usage

### Standard cleanup

```bash
sh clean.sh
```

### Aggressive cleanup

```bash
sh aggressive-clean.sh
```

## Warning

Use at your own risk.

The aggressive script clears Dalvik cache and forces Android to rebuild optimized app code on reboot.

Do NOT interrupt first boot after aggressive cleanup.

## License

MIT
