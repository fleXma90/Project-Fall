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
