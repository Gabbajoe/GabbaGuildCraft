## 1.8.0 — 2026-10-18

- German UI and exports on deDE clients; English on other clients. Game-provided names and effects keep the client language.
- Add the saved “Show materials & transmutations” filter, enabled by default, for oils, crafting materials and transmutation outputs.
- Retry missing data for up to 20 seconds and list the affected recipes and missing fields. Hidden recipes no longer block the selected export.
- Disable export/copy while selected recipes are incomplete; retain the last valid saved export.
- Clarify the “Read recipes → Save export → Reload now” workflow.
- Validate DE/EN exports, large recipe lists and reagents, delayed loading, timeout handling, filters and packaging with automated tests. Live-client verification remains necessary.
