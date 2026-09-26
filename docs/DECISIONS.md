# Entscheidungen

| ID | Status | Entscheidung |
|---|---|---|
| D01 | Feste Anforderung | Godot-Projekt, Smartphone Landscape + Desktop |
| D02 | Feste Anforderung | Touch: linker Joystick, rechts Attack und Dodge |
| D03 | Feste Anforderung | Desktop WASD+Maus; Controller LS + RT + LT |
| D04 | Feste Anforderung | Keine Zielhilfe / kein Lock-on |
| D05 | Feste Anforderung | Nahkampfwaffen + Run-Builds statt permanenter Stat-Metaprogression |
| D06 | Konzeptkern | Abstieg durch Floors und echte Löcher/offene Kanten |
| D07 | Feste Anforderung | `Forgefall` verworfen; Codename `Project Fall` bis Namensentscheidung |
| D08 | Feste Anforderung | Normale Kampfflächen ohne klassische Randwände/Geländer/unsichtbare Randbarrieren |
| D09 | Entwurfsstandard | Touch/Controller Facing = letzter bewusster Stickinput; Desktop Maus unabhängig |
| D10 | **Aktualisiert 24.09.2026** | Technisch 3D statt 2D: CharacterBody3D, Y-Schwerkraft, XZ-Bewegung, feste 2.5D/isometrische Kamera |
| D11 | **Aktualisiert 24.09.2026** | Art Direction: stylized low-/mid-poly 3D, nicht Pixel-Art; M0/M1 nur Dummy-Primitiven |
| D12 | **Aktualisiert 24.09.2026** | Produktionspipeline später: Konzept → optional AI-to-3D → Blender Master → optional Mixamo → Blender Cleanup/Custom Anim → GLB → Godot |
| D13 | Entwurfsstandard | Produktionsanimationen in-place; Weltbewegung bleibt Godot-Gameplaycode |
| D14 | Entwurfsstandard | Waffen separate Modelle/Szenen mit stabilem Weapon-Mount/Adapter |
| D15 | Arbeitsregel | M0/M1 zuerst; M2 und Art-Vertical-Slice separat freigeben |
| D16 | Entwurfsstandard | M1: eine offene Plattform, Hammer, drei Dummies, Fall/Respawn |
| D17 | Entwurfsstandard | M2: zwei Floors, echte Gegner, echter Sturz eine Ebene tiefer |
| D18 | **Aktualisiert 25.09.2026 (M1.1)** | Schlagrichtung folgt im Windup der Ausrichtung, fixiert erst bei ACTIVE; Recovery frei. Bewegung bei gehaltenem Angriff unverändert (Multiplikator 1.0). Hammer 0.26/0.12/0.42 s |
| D19 | **Freigabe 25.09.2026 (M2A)** | Erste aktive Kampfbegegnung: ein Scrapling, Spielerschaden, iFrames wirksam, Sieg/Niederlage/Neustart, Kampfmodus als Standard; restlicher M2 gesperrt |
| D20 | **Entscheidung 25.09.2026 (M2B)** | Attack-Hold bleibt eine erlaubte Eingabemethode und wird nicht künstlich bestraft |
| D21 | **Entscheidung 25.09.2026 (M2B)** | Kein zusätzlicher Hammer-Cooldown |
| D22 | **Entscheidung 25.09.2026 (M2B)** | Zielrichtung: bewegungsorientierter Gruppenkampf (Richtung, Positionierung, Zielwechsel, Ausweichen statt Tastenfrequenz) |
| D23 | **Testprofil 25.09.2026 (M2B)** | Gegner-Benommenheit 0.20 s (Profil B) ist ein Testprofil, keine beschlossene Balance; Standard bleibt Profil A (0.40 s) |
| D24 | **Nutzerentscheidung 25.09.2026 (M2C)** | Profil B (0.20 s Scrapling-Benommenheit) ist der normale Arbeitsstand, weil es sich im Gruppenkampf besser anfühlte; nicht endgültig ausbalanciert, keine vollständige Hardware-/Balanceabnahme. Profil A bleibt für alte Tests/Vergleiche |
| D25 | **Nutzerentscheidung 25.09.2026 (M2C)** | Scraplings bleiben einfache, kontrollierbare Gegner; Schwierigkeit soll aus Gegnerrollen und Positionierung entstehen, nicht aus mehr HP/Tempo |
| D26 | **Umsetzung 25.09.2026 (M2C)** | Funkenwerfer-Bolzen: Kontakt während Dodge-iFrames verbraucht den Bolzen ohne Schaden/Knockback (nur dieser Projektiltyp; Nahkampfregeln unverändert) |
| D27 | **Nutzerentscheidung 25.09.2026 (M2C-Nachtrag)** | Funkenwerfer war verständlich, aber zu leicht auszuweichen. Umgesetzt als umschaltbares Schussprofil „Scharf“ (spätere Festlegung 0.55/0.70 s, Bolzen 11 m/s), Standardstart; „Standard“ bleibt wählbar. Keine Zielvorhersage |
| D28 | **Nutzerauftrag 25.09.2026 (M2D)** | Zweite Ebene: nach dem Räumen öffnet sich eine Luke im Boden (regulärer Abstieg ohne Schaden); Sturz über die Kante von Ebene 1 führt jederzeit auf Ebene 2 mit Sturzschaden |
| D29 | **Nutzerentscheidung 25.09.2026 (M2D)** | Ebene 2 mit neuer Form (Ring um einen Schacht) und erneut Mischkampf (2 Scraplings + 1 Funkenwerfer) |
| D30 | **Nutzerentscheidung 25.09.2026 (M2D)** | Sturz von Ebene 2 = Niederlage mit Ergebnisanzeige, Neustart ab Ebene 1 |
| D31 | **Umsetzung 25.09.2026 (M2D)** | Landung an validiertem sicherem Punkt nahe der Sturzstelle durch stetige horizontale Fallführung (kein Teleport); Landeschutz 0.75 s nur gegen Kampftreffer; Sturzschaden 12 % max HP als Startwert |
| D32 | **Arbeitsregel 25.09.2026 (M2D)** | Commit erst später gemeinsam mit der zweiten Ebene und nur auf ausdrückliche Anweisung |
| D33 | **Nutzerentscheidung 25.09.2026 (M2D.1)** | Nur die aktuelle Ebene ist sichtbar; darunter neutrale Tiefe (Dunkelheit/Glut/Nebel), kein sichtbarer nächster Floor. Beim Fall verschwindet die alte Ebene, die neue erscheint erst im Übergang (Reveal). Echter kontinuierlicher Fall bleibt, kein Schwarzbild/Teleport. Luke statt magischem Portal |
| D34 | **Nutzerentscheidung 25.09.2026 (M2D.1)** | Prototyp-Regeln, nicht final: Ebene-2-Sturz = Niederlage (nur ohne Ebene 3), 12 Sturzschaden (Testwert, keine künstliche Erhöhung vor Clear-Belohnungen), 0.75 s Landeschutz (später sichere Aktivierung statt langer iFrames). Mechanik M2D eingefroren; nächster Schritt danach M3 (XP, Floor-Belohnung, Run-Build-Entscheidungen) |
| D35 | **Nutzerentscheidung 25.09.2026 (M2D.2)** | Kantensturz landet so sauber wie der Lukenabstieg: senkrechter Fall (nur kurz abklingender Schwung), kein schräges Lenken. Stattdessen wird die noch verborgene Ebene 2 samt Gegnern versetzt. Übergang ohne „Schnitt“: an die Fallhöhe gekoppelte Überblendung (Ebene 1 zieht nach oben weg, Ebene 2 taucht überlappend auf). Ersetzt die Fallführung aus D31 |
| D36 | **Freigabe 26.09.2026 (M3A)** | Run-Progression V1: zwei getrennte Systeme – XP/Level/Attribute (Live-Level-Up ohne Pause, Punkte frei und selbst verteilt) und Floor-Clear-Upgrade (Pflicht 1 aus 3 vor dem regulären Abstieg). Keine permanente Progression |
| D37 | **Nutzerentscheidung 26.09.2026 (M3A)** | XP fallen als sichtbare Orbs, die in der Nähe magnetisch eingesammelt werden (auch nach Kantensieg); keine Gutschrift direkt beim Kill |
| D38 | **Umsetzung 26.09.2026 (M3A)** | Orbs einer geräumten Ebene werden eingesaugt/gutgeschrieben; Orbs einer vorzeitig verlassenen, nicht geräumten Ebene verfallen. Clear im Moment des Sturzes: Belohnung und XP bleiben, Auswahl nach der Landung vor Kampfstart |
| D39 | **Umsetzung 26.09.2026 (M3A)** | Effektive Werte = Basisressource × Attributfaktor × Upgradefaktor (Bogen/Reichweite additiv), bei jeder Änderung vollständig neu berechnet. Sturzschaden bleibt 12 % der Basis-Max-HP. Vitalität heilt nie |
| D40 | **Umsetzung 26.09.2026 (M3A)** | Stats: Taste C / Controller View-Back / STATS-Button; Esc/B schließen nur Stats; nie im Fall oder hinter anderen Overlays. Upgrade-Auswahl ohne Überspringen/Reroll, RNG pro Run seedbar |
| D41 | **Freigabe 26.09.2026 (M3B)** | Floor Variety über sechs handgebaute, validierte Vorlagen; zufällig ist nur die Auswahl pro Run (Ebene 1 LOW/MEDIUM, Ebene 2 MEDIUM/HIGH, nie doppelt). Kein Generator |
| D42 | **Umsetzung 26.09.2026 (M3B)** | Getrennte Zufallsströme: Upgrade-Karten (`RunState.rng`, unverändert) und Floors/Slots (`RunState.floor_rng`, aus dem Run-Seed abgeleitet oder per `floor_seed`) |
| D43 | **Umsetzung 26.09.2026 (M3B)** | Landing-Slot passend zur Absprungstelle; verborgene Ebene 2 wird darunter ausgerichtet (keine Spielerlenkung, wie M2D.2) |
| D44 | **Umsetzung 26.09.2026 (M3B)** | Vorlagen werden für die feste Kamera gestaltet: Validator-Regel für Spawn-Slots relativ zum Spielerstart (vorne 5 m, hinten 7.5 m, seitlich tiefenabhängig ≈ 7 m), damit Gegner zu Kampfbeginn auch in 4:3 und nicht unter der HUD-Zeile stehen |
| D45 | **Umsetzung 26.09.2026 (M3B)** | Im Abstieg nutzen alle Gegner den lokalen Lückenumweg; feste Szenarien unverändert ohne. Kein NavMesh/Pathfinding. Nach einem Teleport (Neustart) ein Physiktick ohne Bewegung, damit Gegner nicht aus veralteten Positionen anderer Körper geschoben werden |
| D46 | **Arbeitsregel 26.09.2026 (M3B)** | M2D-/M3A-Regressionstests laufen auf zwei Testvorlagen mit der früheren festen Geometrie (nie im Zufallspool) |
