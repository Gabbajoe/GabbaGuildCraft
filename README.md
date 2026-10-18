<p align="center"><img src="curseforge/logo.png" width="160" alt="GabbaGuildCraft – Hammer und Rezeptbuch"></p>
<h1 align="center">GabbaGuildCraft</h1>
<p align="center">Deine Rezepte. Deine Gilde. Alles griffbereit.</p>
<p align="center"><a href="https://github.com/Gabbajoe/GabbaGuildCraft/actions/workflows/ci.yml"><img src="https://github.com/Gabbajoe/GabbaGuildCraft/actions/workflows/ci.yml/badge.svg" alt="CI"></a> <a href="https://github.com/Gabbajoe/GabbaGuildCraft/releases/latest"><img src="https://img.shields.io/github/v/release/Gabbajoe/GabbaGuildCraft" alt="Release"></a> <img src="https://img.shields.io/badge/license-MIT-gold" alt="MIT"></p>
<p align="center"><a href="README.en.md">English</a> · <a href="https://github.com/Gabbajoe/GabbaGuildCraft/releases/latest">Download</a> · <a href="https://kellerkind.info/gabbacraft/">GabbaCraft</a> · <a href="https://github.com/Gabbajoe/GabbaGuildCraft/issues">Fehler melden</a></p>

GabbaGuildCraft liest deine **gelernten Berufsrezepte** in WoW Classic ein und macht daraus übersichtliche Listen für Discord und eine teilbare Rezeptseite. Entwickelt für Saftladen auf Soulseeker.

## Was kann das Addon?

- Rezepte mit Zutaten, Herstellungsmengen, Werten und Effekten einlesen.
- Nach Rezepten suchen und nach Relevanz oder Ausrüstungslevel filtern.
- Discord-Text in passenden Nachrichtenlängen kopieren, auf Wunsch mit Wowhead-Links.
- Einen HTML-Export in WoWs SavedVariables vorbereiten und in GabbaCraft hochladen.
- Über das eigene **Minimap-Symbol** das Fenster öffnen und schließen; per Ziehen verschieben.
- Mit **„Jetzt /reload“** den gespeicherten Export auf die Festplatte schreiben.

Keine zusätzlichen Addon-Bibliotheken nötig. Das Addon selbst verbindet sich weder mit Discord noch mit einem Webserver. Die deutsche Spieloberfläche funktioniert auch mit englischen Rezeptdaten; die Website bietet Deutsch und Englisch.

Die Oberfläche und Exporttexte folgen der WoW-Sprache: Deutsch bei deDE, sonst Englisch. Der gespeicherte Haken **„Materialien & Transmutationen anzeigen“** ist standardmäßig aktiv und berücksichtigt auch Öle, Treibstoffe und Transmutationen.

## Installation

1. Lade **GabbaGuildCraft-1.8.1.zip** unter [Releases](https://github.com/Gabbajoe/GabbaGuildCraft/releases/latest) herunter. Verwende das fertige Addon-ZIP, nicht GitHubs „Source code“.
2. Beende WoW und entpacke die ZIP-Datei.
3. Kopiere den enthaltenen Ordner **GabbaGuildCraft** in `Interface/AddOns` deiner Spielinstallation. Für Classic Era zum Beispiel:

   ```text
   C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\GabbaGuildCraft
   ```

   Im deutschen Explorer kann `Program Files (x86)` als `Programme (x86)` erscheinen. Über Battle.net → Zahnrad neben „Spielen“ → „Im Explorer anzeigen“ findest du deinen tatsächlichen WoW-Ordner. Unter Linux und macOS gilt dieselbe Ordnerstruktur innerhalb deiner Installation.
4. Prüfe, dass `GabbaGuildCraft.toc` **direkt** in diesem Ordner liegt – keine doppelte GabbaGuildCraft-Ordnerebene.
5. Starte WoW neu und aktiviere GabbaGuildCraft in der Addon-Liste der Charakterauswahl.

Unterstützt wird **WoW Classic Hardcore** mit dem **Classic-Era-Client 1.15.9**. Burning Crusade Classic und Retail werden nicht unterstützt. Die neuen Bedienelemente sind automatisiert mit nachgebildeten WoW-APIs geprüft; ein Spieltest dieser Version steht noch aus.

## Rezepte veröffentlichen

1. Öffne deinen Beruf und setze die Filter im Berufsfenster zurück.
2. Klicke auf das Hammer-Buch-Symbol an der Minimap oder gib `/ggc` ein.
3. Klicke **„Rezepte einlesen“** und prüfe Suche und Filter.
4. Klicke **„Export speichern“** und anschließend **„Jetzt /reload“**. Der zweite Button wird erst nach erfolgreichem Speichern aktiv. Änderungen an Suche oder Filtern erfordern erneutes Speichern. Im Kampf wartet der Button auf das Kampfende.
5. Öffne [GabbaCraft](https://kellerkind.info/gabbacraft/), melde dich mit Discord an und lade unter **„Meine Werkstatt“** diese Datei hoch:

   ```text
   C:\Program Files (x86)\World of Warcraft\_classic_era_\WTF\Account\DEIN_ACCOUNT\SavedVariables\GabbaGuildCraft.lua
   ```

   Wähle deinen tatsächlichen Account-Ordner und die Datei ohne `.bak`. Das Addon-Verzeichnis ist nicht der Exportordner. Die Saftladen-Website benötigt für Uploads die Discord-Rolle **Crafter**; öffentliche Rezeptseiten kannst du ohne diese Rolle lesen.
6. Teile den Link zu deiner Rezeptseite. Für einen anderen Beruf oder neue Rezepte wiederholst du den Export.

**Nur für Discord:** „Text markieren“ → `Strg+C` → in Discord einfügen. Bei mehreren Nachrichten mit „Weiter“ umblättern. Dafür sind Website und Anmeldung nicht nötig.

`/gts`, `/schneiderdiscord`, `/gildenrezepte` und `/gabbaguildcraft` öffnen das Fenster ebenfalls. Der Minimap-Button merkt sich seine Position accountweit. Wie alle SavedVariables wird auch diese beim Ausloggen oder Neuladen gespeichert.

## Wenn etwas fehlt

| Problem | Lösung |
| --- | --- |
| Addon fehlt in der Liste | ZIP entpacken, Ordnerstruktur und Spielversion prüfen, WoW vollständig neu starten. |
| Rezepte fehlen | Beruf öffnen, dessen Filter zurücksetzen, im Addon Suche und Relevanzfilter prüfen. |
| Itemdaten noch nicht geladen | Kurz warten und erneut „Rezepte einlesen“ klicken. |
| Exportdatei fehlt oder ist alt | Erst „Export speichern“, dann „Jetzt /reload“; den richtigen Account unter SavedVariables wählen. |
| Jetzt /reload ist ausgegraut | Zuerst einen gültigen Export mit „Export speichern“ vorbereiten. |
| Kein Zugriff auf die Werkstatt | Discord-Konto und Rolle „Crafter“ auf Saftladen prüfen. |

Beim Umstieg vom alten GuildTailor das Spiel beenden und den alten Addon-Ordner entfernen. Vorhandene Exportvariablen bleiben kompatibel. Nicht mehrere Versionen gleichzeitig installieren.

## Entwicklung & Releases

```sh
LUA=lua5.1 LUAC=luac5.1 bash tests/run_tests.sh
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/build_package.py --output-dir dist --tag v1.8.1
```

Die Pipeline prüft Lua und Exportverhalten und baut ein reproduzierbares ZIP mit SHA-256-Prüfsumme. Ein Versions-Tag erzeugt einen GitHub-Release; ein eingerichtetes CurseForge-Projekt erhält dasselbe Paket. Einrichtung und Veröffentlichung: **[RELEASING.md](RELEASING.md)**. Projektbeschreibung und Logo: **[curseforge/SETUP.md](curseforge/SETUP.md)**.

Dies ist ausschließlich das Addon-Repository. Website, Discord-Bot, Companion-App und deren Zugangsdaten sind nicht enthalten.

## Lizenz & Artwork

[MIT](LICENSE). Das eigene Hammer-und-Rezeptbuch-Motiv wurde mit KI-Unterstützung erstellt; [Motiv und Prompt](docs/artwork/PROMPT.md). World of Warcraft ist eine Marke von Blizzard Entertainment. Dieses Community-Projekt ist nicht mit Blizzard verbunden.

Fehlende Daten lädt das Addon bis zu 20 Sekunden nach. Bleiben Lücken, zeigt es Rezeptnamen und fehlende Angaben an. Export und Textkopie bleiben gesperrt, bis die ausgewählten Rezepte vollständig sind; der letzte gespeicherte Export bleibt erhalten. Danach erneut einlesen oder die betroffenen Rezepte gezielt herausfiltern.
