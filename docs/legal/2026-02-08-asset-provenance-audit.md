# Asset Provenance and License Audit (2026-02-08)

This note records evidence gathered for bundled dictionary data and fonts in this repository.
It is a technical/legal trace log and not legal advice.

## Scope

- Repo: `khmerdictionary-ios`
- Assets reviewed:
  - `KhmerDictionary/Resources/Data/dict.db`
  - `KhmerDictionary/Resources/Fonts/suwannaphum_regular.ttf`
  - `KhmerDictionary/Resources/Fonts/suwannaphum_bold.ttf`
  - `KhmerDictionary/Resources/Fonts/suwannaphum_light.ttf`
  - `KhmerDictionary/Resources/Fonts/tacteing.ttf`

## Evidence Summary

### 1) Dictionary DB lineage

- Current app DB SHA-1:
  - `c8fbdf591b8665c589c7668832516d3582275a4d`
- Row count:
  - `dict` rows: `17,328`
- DB is byte-identical to legacy Android DB inside:
  - `Khmer-Dictionary/db/room_sqlite.zip` (contains `dict.db`)
- Legacy Android code reference (modern package) points DB download to:
  - `https://github.com/sovathna/Khmer-Dictionary/raw/master/db/room_sqlite.zip`
  - File: `app/src/main/java/io/github/sovathna/khmerdictionary/config/Const.kt`
- Older lineage (2014 package) points DB download to:
  - `http://hongsovathna.com/mobile/khtokh.zip`
  - File path in history: `app/src/main/java/com/indiev/chuonnathkhmerdictionary/Constant.java` at commit `7fe6600`

### 2) Dictionary DB license signals

- No top-level `LICENSE`, `LICENSE.md`, or `COPYING` found in the upstream `sovathna/Khmer-Dictionary` repo.
- Historical app string in commit `7fe6600` claims:
  - Data source: Buddhist Institute
  - License claim: LGPL
  - File: `app/src/main/res/values/strings.xml` (`otherdes`)
- No formal license artifact for the DB itself was found in the current upstream repo.

### 3) Font evidence

- `Suwannaphum` fonts SHA-1:
  - regular: `a79a24c9e9b0f419b4826d3d59cb64256cacd4dc`
  - bold: `a02b43fdc707f19443121291a31df407a434c1ff`
  - light: `4a51aae7a8309a39066e64bf6b8cad63674cd866`
- Font metadata (`nameID=13`) states:
  - "This Font Software is licensed under the SIL Open Font License, Version 1.1"
  - Also references project authors and `github.com/danhhong/Suwannaphum`
- `Tacteing` font SHA-1:
  - `5d885fc7bfd2c628550bf42b895b7b56539e5f32`
- Font metadata (`nameID=0`) states:
  - "By Om Mony ,All rights reserved 1991(c)"

## Distribution Risk Decision (Current State)

- `dict.db`: **BLOCKED for public redistribution** until rights are confirmed in writing.
- `suwannaphum_*`: **ALLOWED** under OFL obligations (include attribution/license text).
- `tacteing.ttf`: **BLOCKED** unless explicit redistribution permission/license is obtained.

## Required Remediation Before Public Release

1. Replace or remove `tacteing.ttf`, or secure explicit permission from the rightsholder.
2. Confirm and document DB redistribution rights in a verifiable written artifact.
3. Keep legal notices aligned with final shipped assets and licenses.

## Key Links

- Legacy DB URL constant:
  - `https://raw.githubusercontent.com/sovathna/Khmer-Dictionary/master/app/src/main/java/io/github/sovathna/khmerdictionary/config/Const.kt`
- Historical Buddhist Institute / LGPL claim:
  - `https://raw.githubusercontent.com/sovathna/Khmer-Dictionary/7fe6600/app/src/main/res/values/strings.xml`
- Suwannaphum OFL:
  - `https://raw.githubusercontent.com/danhhong/Suwannaphum/master/OFL.txt`
