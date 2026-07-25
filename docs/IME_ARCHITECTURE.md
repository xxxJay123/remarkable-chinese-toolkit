# Chinese IME architecture

## Goal

Provide native Chinese text entry on reMarkable without replacing Xochitl or changing the notebook file format.

Target input schemes:

- Jyutping / Hong Kong Traditional Chinese
- Pinyin / Traditional and Simplified Chinese
- Cangjie 5
- Quick 5

Target hardware:

- reMarkable 2 (`arm32`)
- reMarkable Paper Pro family (`aarch64`)

## Layers

```text
Type Folio / on-screen keys
            |
            v
Qt Quick candidate and composition UI
            |
            v
RimeController (stable project API)
            |
            v
librime + separately licensed schemas
            |
            v
Unicode commit bridge
            |
            v
Focused Xochitl text editor
```

### 1. Engine

`RimeController` is the stable boundary around `librime`. It owns one Rime session and exposes:

- pre-edit text
- current candidate page
- committed Unicode text
- available schemas
- current schema
- composition commands

The engine does not depend on Xochitl internals, so it can be tested in a desktop Linux Qt environment and in a standalone reMarkable application.

### 2. UI

The QML UI follows e-ink constraints:

- black, white, and gray only
- no animation
- large touch targets
- explicit page controls
- bounded redraw regions
- candidate text rendered with CJK-capable fonts

The first prototype includes its own output area. The production overlay will remove that area and commit text to the previously focused Xochitl object.

### 3. Unicode commit bridge

The preferred integration is an in-process extension loaded with a compatible extension framework. It will:

1. remember the focused Xochitl text object before the candidate overlay takes focus;
2. intercept Type Folio key events only while Chinese mode is enabled;
3. send committed UTF-8 text to the target as a Qt input-method commit event;
4. pass through keys unchanged when Chinese mode is disabled.

This bridge is intentionally not implemented against 3.28 Beta. Xochitl is proprietary and has no stable plugin ABI, so the bridge must be validated with the stable firmware and its matching official SDK.

Direct mutation of `.rm` notebook files is not part of the IME design.

### 4. Packaging

Device packages will be split by:

- product architecture
- reMarkable software version
- matching SDK build
- extension-framework compatibility

The installer must refuse unknown firmware instead of assuming compatibility.

## Data directories

The prototype uses:

```text
/home/root/.local/share/remarkable-chinese-toolkit/rime/
├── shared/    schemas, dictionaries, and deployed data
└── user/      user dictionary and preferences
```

Both directories live under `/home`, so they survive normal OS updates.

## Stable-release gate

The Xochitl bridge can start only when all conditions are true:

- reMarkable 3.28 is released to the stable channel;
- the official 3.28-compatible SDK is published;
- the target extension framework supports that stable build;
- the official release is checked for native Chinese keyboard support;
- the official release is checked for Chinese handwriting conversion;
- a recovery path is documented and tested.

If the official software already provides equivalent Chinese input, this project will not install a competing Xochitl patch by default.

## Acceptance tests

### Composition

- Jyutping produces Hong Kong Traditional candidates.
- Pinyin can switch between Traditional and Simplified output.
- Cangjie and Quick accept physical and on-screen keys.
- Candidate paging works without animation artifacts.
- Backspace edits composition before deleting committed text.

### Text

- ASCII and Chinese can be mixed.
- punctuation uses the selected schema rules.
- multiline commit works in a native text block.
- common Cantonese text renders correctly.
- HKSCS and extension characters report missing font coverage separately.

### Compatibility

- Chinese mode can be disabled instantly.
- non-text views receive untouched keyboard events.
- reboot returns to stock when the extension framework is tethered.
- unsupported firmware is rejected before installation.
