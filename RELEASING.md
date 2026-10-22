# Releases

## Lokal prüfen und bauen

Voraussetzungen: Python 3.10+, Lua 5.1 und luac 5.1. Keine Python-Pakete nötig.

```sh
LUA=lua5.1 LUAC=luac5.1 bash tests/run_tests.sh
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/build_package.py --output-dir dist --tag v1.8.2
```

Das ZIP hat unabhängig vom Checkout-Namen genau einen obersten Ordner `GabbaGuildCraft`. Nur ausdrücklich freigegebene Laufzeit- und Dokumentationsdateien werden verpackt. Tests, Buildskripte, Git-Dateien und große Artwork-Quelldateien bleiben draußen. Gleicher Quellstand mit derselben Python-/zlib-Version ergibt denselben SHA-256-Hash. Andere zlib-Versionen können identische Inhalte unterschiedlich komprimieren. Für Website und Mirrors wird deshalb die fertige ZIP-Datei aus dem GitHub-Release unverändert übernommen.

## Veröffentlichen

1. TOC-Version, README-Downloadversion, CHANGELOG und `curseforge/CHANGELOG-VERSION.md` aktualisieren.
2. Tests und Ingame-Prüfung durchführen: Fenster per Minimap und `/ggc` öffnen/schließen, Symbol verschieben, Beruf einlesen, HTML speichern, Neu laden, SavedVariables-Datei prüfen. Combat-Guard und bestehende Discord-Exportfunktionen kontrollieren.
3. Änderungen nach `main` pushen und grüne CI abwarten.
4. Passenden Tag setzen und pushen, z. B. `git tag v1.8.2` und `git push origin v1.8.2`.
5. Release-Workflow abwarten und ZIP samt SHA-256-Datei im GitHub-Release prüfen.

`vVERSION` muss exakt mit der TOC übereinstimmen. `-alpha.N`/`-dev.N` werden als Alpha, `-beta.N`/`-rc.N` als Beta hochgeladen und bei GitHub als Prerelease markiert. Versionen ohne Suffix sind normale Releases. Bestehende GitHub-Release-Assets werden bei einer Wiederholung nicht überschrieben.

## CurseForge

Siehe [Projekt-Einrichtung](curseforge/SETUP.md). Benötigt werden Actions-Variable `CURSEFORGE_PROJECT_ID` und Secret `CURSEFORGE_API_TOKEN`. Ohne beide veröffentlicht die Pipeline nur auf GitHub und meldet den ausgelassenen CurseForge-Schritt.

Der Uploader ermittelt die exakten Versions-IDs aus dem Classic-Era-TOC-Interface (derzeit 1.15.9 für Classic Hardcore). Fehlende oder mehrdeutige Zuordnung bricht ab; es werden keine Versions-IDs geraten. Ein manueller Workflow prüft die Konfiguration ohne Datei-Upload. Das Secret wird ausschließlich aus der Umgebung gelesen, nicht geloggt und bei HTTP-Weiterleitungen nicht weitergegeben.

Nach einem unklaren Uploadfehler im Autoren-Dashboard prüfen, ob die Datei bereits angekommen ist. Upload-POSTs werden nicht automatisch wiederholt.

Offizielle API: https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-api
