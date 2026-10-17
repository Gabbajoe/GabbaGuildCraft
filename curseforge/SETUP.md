# CurseForge-Projekt einrichten

Die Dateien sind vorbereitet. Ein CurseForge-Projekt muss im angemeldeten Autorenkonto angelegt werden; das Repository erzeugt es nicht automatisch.

1. Öffne https://authors.curseforge.com/#/projects/create/choose-game und wähle World of Warcraft / Addon.
2. **Name:** GabbaGuildCraft
3. **Zusammenfassung:** Share your learned WoW Classic profession recipes with your guild through Discord and HTML exports.
4. **Logo:** `curseforge/logo.png` (512 × 512 PNG).
5. **Beschreibung:** Inhalt von `curseforge/DESCRIPTION.md`.
6. Wähle passende angebotene Kategorien, insbesondere Berufe/Professions. Lizenz: MIT.
7. Source: https://github.com/Gabbajoe/GabbaGuildCraft — Issues: https://github.com/Gabbajoe/GabbaGuildCraft/issues
8. Notiere die **numerische Projekt-ID** aus dem erstellten Projekt. Hinterlege sie als GitHub Actions Repository-Variable `CURSEFORGE_PROJECT_ID`.
9. Erzeuge unter https://authors.curseforge.com/#/settings/api-tokens einen Autoren-API-Token und hinterlege ihn als Actions-Secret `CURSEFORGE_API_TOKEN`. Token niemals in Dateien, Commits oder Chat einfügen.
10. Starte den GitHub-Workflow **CurseForge check**. Er prüft Token und exakte Spielversions-Zuordnung, nicht Projektbesitz oder Freischaltung.
11. Nach Einrichtung kann der Release-Workflow für den vorhandenen Versions-Tag erneut gestartet werden. Er behält den GitHub-Release und lädt das ZIP zu CurseForge. Nach einem unklaren Uploadfehler zuerst im CurseForge-Dashboard nachsehen, um doppelte Dateien zu vermeiden.

GitHub-Einstellungen: https://github.com/Gabbajoe/GabbaGuildCraft/settings/secrets/actions (Token) und https://github.com/Gabbajoe/GabbaGuildCraft/settings/variables/actions (Projekt-ID).

Die Erstveröffentlichung unterliegt CurseForges Projekt-/Dateiprüfung. Ein erfolgreiches API-Upload-Ergebnis bedeutet nicht automatisch, dass die Datei bereits öffentlich freigegeben ist.
