# Third-Party Notices

This project includes or may reference third-party data and font assets.
Those assets are not automatically covered by the repository code license.

## Bundled Assets In This Repo

1. Dictionary database:
   - Path: `KhmerDictionary/Resources/Data/dict.db`
   - Source: legacy project import
   - License: verify before redistribution

2. Khmer fonts:
   - Paths:
     - `KhmerDictionary/Resources/Fonts/suwannaphum_regular.ttf`
     - `KhmerDictionary/Resources/Fonts/suwannaphum_bold.ttf`
     - `KhmerDictionary/Resources/Fonts/suwannaphum_light.ttf`
     - `KhmerDictionary/Resources/Fonts/tacteing.ttf`
   - Source: legacy project import
   - License: verify before redistribution

## Imported Dictionary Sources (Generated Releases)

The builder tool at `tools/dictionary-builder` stores source-level provenance in
`dict_attribution(source_id, license, attribution, source_url, ...)`.

When generating and distributing updated dictionary databases:

1. Set accurate `license` and `attribution` in build config source entries.
2. Preserve required attribution in product/legal screens and release artifacts.
3. Ensure all imported sources are legally compatible with your distribution model.

Example (Wiktionary-derived datasets):
- Often governed by CC BY-SA and/or GFDL terms with attribution/share-alike duties.
- Confirm exact terms from the specific upstream dataset before shipping.
