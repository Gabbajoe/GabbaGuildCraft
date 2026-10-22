# Changelog

## 1.8.2 — 2026-10-22

- Accept name-only tooltips for crafting materials, including alchemy dyes and transmutation outputs, so they no longer block export as missing stats. Empty or mismatched tooltips and incomplete equipment, consumable, device and explosive tooltips still require loading.

## 1.8.1 — 2026-10-18

- Correct supported clients to WoW Classic Hardcore (Classic Era 1.15.9). Burning Crusade Classic 2.5.6 was listed by mistake and is not supported.
- Remove the 20506 interface and reject non-Era interfaces during packaging and CurseForge uploads.
- Includes the 1.8.0 improvements: German/English UI, materials and transmutation filter, automatic retries for missing recipe data, and complete reagent exports.
- Existing SavedVariables and recipe exports remain unchanged. Automated regression tests pass; an in-game test of the new version is still pending.

## 1.8.0 — 2026-10-18

- German UI and exports on deDE clients; English on other clients. Game-provided names and effects keep the client language.
- Add the saved “Show materials & transmutations” filter, enabled by default, for oils, crafting materials and transmutation outputs.
- Retry missing data for up to 20 seconds and list the affected recipes and missing fields. Hidden recipes no longer block the selected export.
- Disable export/copy while selected recipes are incomplete; retain the last valid saved export.
- Clarify the “Read recipes → Save export → Reload now” workflow.
- Validate DE/EN exports, large recipe lists and reagents, delayed loading, timeout handling, filters and packaging with automated tests. Live-client verification remains necessary.

## 1.7.0 — 2026-10-18

- Add a movable minimap button with an original crafting icon and persistent position.
- Add “Neu laden” after a successful HTML save, with a combat guard.
- Replace outdated export-helper instructions in the addon with direct SavedVariables upload guidance.
- Publish the addon as an independent GitHub project with German and English documentation.
- Add Lua regression tests, reproducible release ZIPs, SHA-256 checksums and optional CurseForge publishing.
- Existing recipe exports and SavedVariables remain compatible.

Automated tests use simulated WoW APIs; an in-game smoke test of the new controls is still pending.

## 1.6.0

Existing website-distributed version: recipe, spell and reagent IDs in HTML exports; profession scanning, filters, effects and Discord export.
