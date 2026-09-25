# Assets, Herkunft und Produktionsstatus

## Referenzen

Die PNGs in `references/` wurden im Projektgespräch als Konzeptbilder erzeugt. Sie sind keine Runtime-Assets, keine Storegrafik und kein freigegebener Markenauftritt. Der darin sichtbare Name `Forgefall` ist verworfen.

## M0/M1

Nur selbst erzeugte Godot-Primitiven/Placeholder verwenden. Keine Lizenzabhängigkeit für den Gameplay-Blockout erzeugen. Engine-Standardschrift ist für Debug/M1 ausreichend.

## Spätere Produktionsassets

Externe, AI-generierte oder durch Dienste bearbeitete Assets benötigen dokumentierte Herkunft. `assets/ASSET_MANIFEST.csv` ist zu ergänzen, bevor ein Asset als production/runtime approved gilt.

Mindestens dokumentieren:

- lokaler Sourcepfad,
- Titel/Asset-ID,
- Ersteller/Tool/Dienst,
- Quelladresse oder Toolbezeichnung,
- Erstell-/Download-Datum,
- Lizenz-/Nutzungsstatus,
- Nachweispfad/Notiz,
- Modifikationen,
- Masterdatei,
- Runtime-Export,
- Status.

Bei AI-to-3D, Mixamo, Texture-Generatoren oder ähnlichen Diensten die **zum tatsächlichen Nutzungszeitpunkt geltenden** Bedingungen prüfen. Keine pauschalen Aussagen aus Erinnerung als Lizenzfreigabe behandeln.

## Blender/MCP

Blender- und MCP-Automatisierung verändert die Herkunft eines fremden Ausgangsassets nicht. Automatisch bereinigtes oder retopologisiertes Fremdmaterial bleibt lizenzpflichtig entsprechend seiner Quelle.

Blender-Masterdateien gelten als Source-Assets. Für den Runtime-Build werden nur benötigte Exporte und Texturen übernommen.

## Keine Referenzextraktion

Keine Figuren, UI-Elemente, Texturen oder Logos aus Quadropus-Rampage-Screenshots ausschneiden oder nachbauen. Inspiration darf sich auf allgemeine Mechanik-/Lesbarkeitsmerkmale beschränken.

## Builds

Produktionsbuilds enthalten keine `references/`, Roh-Blender-Arbeitsstände, QA-Aufnahmen, lokalen SDK-/Enginepfade, Keystores oder Geheimnisse.
