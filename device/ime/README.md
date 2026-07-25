# reMarkable Chinese IME prototype

This directory contains the first device-side Chinese input prototype.

## Current scope

Implemented:

- Qt Quick e-ink UI
- `librime` session lifecycle
- composition and candidate updates
- schema discovery and selection API
- Unicode commit signal
- shared ARM32/AArch64 source

Not implemented yet:

- Xochitl injection
- Type Folio interception
- device package or installer
- bundled Rime schemas/dictionaries
- 3.28 device testing

Do not install this prototype on a device enrolled in the 3.28 Beta Program.

## Dependencies

- matching official reMarkable SDK
- Qt 6 Quick from the SDK
- a cross-compiled `librime`
- separately deployed Rime schema data

Recommended upstream data:

- Jyutping: <https://github.com/rime/rime-cantonese>
- Pinyin: <https://github.com/rime/rime-terra-pinyin>
- Cangjie 5: <https://github.com/rime/rime-cangjie>
- Quick 5: <https://github.com/rime/rime-quick>

Review and preserve each data repository's license before redistribution.

## Build

After activating the matching stable reMarkable SDK:

```bash
cmake -S device/ime -B device/ime/build \
  -DCMAKE_BUILD_TYPE=Release
cmake --build device/ime/build
```

`pkg-config` must be able to find the target build of `librime` as `rime`.

## Runtime data

Default paths:

```text
/home/root/.local/share/remarkable-chinese-toolkit/rime/shared
/home/root/.local/share/remarkable-chinese-toolkit/rime/user
```

Overrides:

```bash
export RM_CHINESE_IME_SHARED_DATA=/path/to/shared
export RM_CHINESE_IME_USER_DATA=/path/to/user
export RM_CHINESE_IME_SCHEMA=jyut6ping3
```

The shared directory must contain deployed Rime schema data before the engine can produce candidates.

## Standalone run

The standalone binary is a validation harness only. On a supported stable firmware it will eventually be run using the official e-paper Qt platform:

```bash
QT_QUICK_BACKEND=epaper \
  ./remarkable-chinese-ime-prototype -platform epaper
```

Do not use this command on 3.28 Beta. A version-gated installer will be added after the stable SDK is available.
