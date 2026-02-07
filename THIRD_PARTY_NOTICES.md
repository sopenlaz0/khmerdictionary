# Third-Party Notices

This file tracks legal/provenance status for bundled third-party assets.
Repository code license does not automatically cover these assets.

## Distribution Status Matrix

| Asset | Path(s) | Provenance Evidence | License Evidence | Redistribution Status |
|---|---|---|---|---|
| Dictionary database | `KhmerDictionary/Resources/Data/dict.db` | Byte-identical to `db/room_sqlite.zip` in legacy repo `sovathna/Khmer-Dictionary`; older code lineage points to `hongsovathna.com/mobile/khtokh.zip` | No license file found in current upstream repo; older app text claims Buddhist Institute source and LGPL, but no formal license artifact included | **BLOCKED for public distribution** until rights are confirmed in writing (App Store/TestFlight/public release) |
| Suwannaphum fonts | `KhmerDictionary/Resources/Fonts/suwannaphum_regular.ttf` `KhmerDictionary/Resources/Fonts/suwannaphum_bold.ttf` `KhmerDictionary/Resources/Fonts/suwannaphum_light.ttf` | Font metadata includes project reference to `github.com/danhhong/Suwannaphum` | Font metadata states SIL Open Font License 1.1; upstream `OFL.txt` available | **ALLOWED** if OFL notice is included and terms are followed |
| Tacteing font | `KhmerDictionary/Resources/Fonts/tacteing.ttf` | Legacy import | Font metadata states: `By Om Mony, All rights reserved 1991(c)`; no permissive redistribution license found | **BLOCKED for redistribution** unless explicit permission/license is obtained |

## Required Actions Before Public Release

1. Replace `tacteing.ttf` with a clearly licensed alternative, or obtain explicit written permission from the rightsholder.
2. Obtain written redistribution rights for `dict.db` from the data rights holder, or rebuild from clearly licensed sources.
3. Keep the Suwannaphum OFL text in release/legal artifacts when shipping those fonts.
4. Keep this file updated when asset sources, hashes, or licenses change.

## Evidence References

- Legacy DB URL in Android source:
  - `https://raw.githubusercontent.com/sovathna/Khmer-Dictionary/master/app/src/main/java/io/github/sovathna/khmerdictionary/config/Const.kt`
- Historical claim about data source/license in older app strings:
  - `https://raw.githubusercontent.com/sovathna/Khmer-Dictionary/7fe6600/app/src/main/res/values/strings.xml`
- Suwannaphum OFL:
  - `https://raw.githubusercontent.com/danhhong/Suwannaphum/master/OFL.txt`

## Imported Dictionary Sources (Generated Releases)

The builder tool at `tools/dictionary-builder` stores per-source attribution in:
`dict_attribution(source_id, license, attribution, source_url, ...)`.

For generated dictionary updates, ensure each source has explicit licensing and required attribution before release.
