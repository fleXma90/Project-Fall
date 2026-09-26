class_name EncounterStats
extends RefCounted
## Kurze lokale Rundenzusammenfassung einer Kampfbegegnung (kein Telemetriesystem).

## CLEARED/SKIPPED nur im Abstieg (Ebene 1 geräumt bzw. per Sturz verlassen).
enum Outcome { RUNNING, VICTORY, DEFEAT, PLAYER_FALL, ABORTED, CLEARED, SKIPPED }

var scenario: String = ""
var profile: String = ""
var outcome: Outcome = Outcome.RUNNING
## Kampfdauer in Physikzeit; Pausen zählen nicht.
var duration: float = 0.0
var damage_taken: float = 0.0
var hits_taken: int = 0
var enemies_total: int = 0
var enemies_hp_defeated: int = 0
var enemies_fall_defeated: int = 0
var enemy_attacks_started: int = 0
var enemy_attacks_active: int = 0
var enemy_attacks_interrupted: int = 0
## Funkenwerfer (nur MIXED): abgefeuerte Schüsse, abgebrochene Aufladungen, angewendete Projektiltreffer.
var shots_fired: int = 0
var charges_interrupted: int = 0
var projectile_hits: int = 0
## Mit Funkenwerfer (Schussteil der Zusammenfassung).
var has_shooter: bool = false
## Abstieg: Sturzschaden bei der Landung auf dieser Ebene (in damage_taken enthalten).
var fall_damage: float = 0.0
## M3B: Floor-Vorlage dieser Ebene im Abstieg (Name und Kantenrisiko).
var floor_template: String = ""


func outcome_name() -> String:
	match outcome:
		Outcome.VICTORY:
			return "Sieg"
		Outcome.DEFEAT:
			return "Niederlage"
		Outcome.PLAYER_FALL:
			return "Spielerfall"
		Outcome.ABORTED:
			return "Abbruch"
		Outcome.CLEARED:
			return "Ebene geräumt"
		Outcome.SKIPPED:
			return "Sturz (Ebene übersprungen)"
	return "läuft"


func to_line() -> String:
	return "%s · Profil %s · %s · %.1f s · Schaden %d (%d Treffer) · besiegt HP %d / Kante %d von %d · Gegnerangriffe %d, ACTIVE %d, vor ACTIVE abgebrochen %d" % [
			scenario, profile, outcome_name(), duration, int(damage_taken), hits_taken,
			enemies_hp_defeated, enemies_fall_defeated, enemies_total,
			enemy_attacks_started, enemy_attacks_active, enemy_attacks_interrupted] + _shooter_part() + _fall_part() + (" · Floor %s" % floor_template if not floor_template.is_empty() else "")


func _shooter_part() -> String:
	if not has_shooter and scenario != "Gemischt":
		return ""
	return " · Schüsse %d (Aufladung abgebrochen %d), Projektiltreffer %d" % [shots_fired, charges_interrupted, projectile_hits]


func _fall_part() -> String:
	return " · Sturzschaden %d" % int(fall_damage) if fall_damage > 0.0 else ""
