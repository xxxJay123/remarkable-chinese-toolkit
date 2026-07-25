# Chinese font reading compatibility

## Current result

reMarkable software `3.28.0.163` has **not been tested** with the legacy Chinese font installer.

This project therefore makes no compatibility claim for:

- installing third-party Chinese fonts on 3.28;
- system CJK fallback inside PDF or EPUB reading;
- variable font weight selection;
- Xochitl library metadata rendering;
- persistence after restart, reboot, or OS update.

The Desktop app and both CLI installers block 3.28 and later firmware until an exact build completes this matrix. An unknown version is blocked as well.

## Why reading tests must be separated

A PDF with embedded Chinese fonts can render correctly even when the system font installer is broken. A useful result must distinguish:

1. document-embedded fonts;
2. fontconfig system fallback;
3. Xochitl UI and library metadata;
4. EPUB rendering and weight selection.

“I can read one Chinese PDF” is not enough to mark an installer as compatible.

## Test gate

Do not run device modifications while enrolled in the reMarkable Beta Program.

Testing a stable build requires:

- exact device model and architecture;
- exact stable software version;
- a current device backup and documented recovery route;
- confirmation of the relevant font paths and fontconfig behaviour;
- a dedicated compatibility change that allowlists only the tested build.

Never replace the 3.28 gate with a broad “allow all newer versions” rule.

## Reading matrix

Record `pass`, `fail`, or `not tested` for every row.

| Area | Test | 3.28.0.163 |
| --- | --- | --- |
| Library | Traditional Chinese filename | Not tested |
| Library | Simplified Chinese filename | Not tested |
| PDF control | Embedded Traditional Chinese font | Not tested |
| PDF control | Embedded Simplified Chinese font | Not tested |
| PDF fallback | No embedded CJK font, Traditional text | Not tested |
| PDF fallback | No embedded CJK font, Simplified text | Not tested |
| EPUB | Traditional Chinese book | Not tested |
| EPUB | Simplified Chinese book | Not tested |
| Typography | Regular, medium, and bold weights | Not tested |
| Coverage | Common Hong Kong characters and HKSCS sample | Not tested |
| Lifecycle | Restart Xochitl | Not tested |
| Lifecycle | Reboot device | Not tested |
| Recovery | Remove installed font and restore stock state | Not tested |
| Update | Behaviour after the next stable OS update | Not tested |

## Evidence required

A compatibility report should include:

- device model;
- software version;
- installer commit;
- font filename, version, and license;
- test document source and whether fonts are embedded;
- screenshots or precise observed results;
- relevant `fc-list` and `fc-match` output with credentials removed;
- restart, reboot, and recovery results.

Only an exact tested build may move from `unverified` to `supported`.
