# GameOverlayMenu

iOS jailbreak tweak — dynamic overlay menu with runtime class detection.

## Features
- Auto-detects Player / Coin / AdManager classes at runtime
- God Mode, Unlimited Coins, No Ads toggles
- Draggable floating button + blur menu

## Build (GitHub Actions)
1. Push to `main` → Actions runs automatically
2. Actions → latest run → Artifacts → download `GameOverlayMenu-deb.zip`

## Install on device
```bash
scp GameOverlayMenu.deb root@<IPHONE_IP>:/var/root/
ssh root@<IPHONE_IP> "dpkg -i /var/root/GameOverlayMenu.deb && ldrestart"
```

Or install via Filza / Sileo / Zebra.

## Manual build (requires macOS + Theos)
```bash
export THEOS=/opt/theos
make package FINALPACKAGE=1
```
