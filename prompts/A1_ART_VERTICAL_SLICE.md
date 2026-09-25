# Folgeauftrag — A1 Art Vertical Slice (nur nach ausdrücklicher Freigabe)

Dieser Prompt autorisiert **nicht** automatisch eine bestimmte externe Plattform. Vor Nutzung kostenpflichtiger/verbundener Dienste oder Lizenzannahmen die konkrete Toolwahl mit dem Nutzer festlegen.

Ziel: genau einen finalnahen visuellen Slice herstellen, ohne Gameplay neu zu schreiben.

Lies `AGENTS.md`, `docs/ASSET_PIPELINE.md`, `docs/ASSET_POLICY.md`, `docs/ART_DIRECTION.md`, `docs/ARCHITECTURE.md`, `docs/STATUS.md` und den letzten Gameplaybericht.

Umfang:

1. Scrap-Golem-Character-Sheet/Turnaround als Produktionsreferenz festlegen.
2. Einen Base Mesh erzeugen oder modellieren; AI-to-3D optional.
3. Blender als Masterquelle verwenden: Cleanup/Retopo/Scale/Materials/Origin.
4. Ein Master-Rig herstellen. Mixamo darf für humanoide Basisanimationen genutzt werden, wenn explizit gewählt; danach in Blender prüfen/retargeten.
5. Ein separater Hammer mit stabilem Weapon-Socket.
6. Minimal benötigte Clips: idle, run, dodge, hit/fall sowie **ein** überzeugender Hammerangriff. In-place.
7. Export als `.glb` und Integration unter dem bestehenden `VisualRoot`/Adapter. Gameplaykollision, Input, Knockback und Attackregeln bleiben unverändert.
8. Ein kleiner finalnaher Gegner + begrenztes Plattform-/Prop-Kit nur wenn der Auftrag dies explizit einschließt.
9. Godot-VFX für Hammertrail/Impact in kleinem Umfang.
10. Desktop + echtes Smartphone performance/lesbar prüfen, soweit Hardware vorhanden.

Keine Massenproduktion weiterer Gegner/Waffen. Der Slice muss zuerst beweisen, dass Pipeline, Deformation, Kamera, VFX und Import funktionieren.

Alle Quellen/Lizenzen/Tools in `assets/ASSET_MANIFEST.csv` dokumentieren. Blender-MCP-Automatisierung darf helfen, ersetzt aber keine visuelle Qualitätskontrolle.
