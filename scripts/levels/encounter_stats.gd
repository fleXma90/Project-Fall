class_name EncounterStats
extends RefCounted
## Kurze lokale Rundenzusammenfassung einer Kampfbegegnung (kein Telemetriesystem).

enum Outcome { RUNNING, VICTORY, DEFEAT, PLAYER_FALL, ABORTED }

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
	return "läuft"


func to_line() -> String:
	return "%s · Profil %s · %s · %.1f s · Schaden %d (%d Treffer) · besiegt HP %d / Kante %d von %d · Gegnerangriffe %d, ACTIVE %d, vor ACTIVE abgebrochen %d" % [
			scenario, profile, outcome_name(), duration, int(damage_taken), hits_taken,
			enemies_hp_defeated, enemies_fall_defeated, enemies_total,
			enemy_attacks_started, enemy_attacks_active, enemy_attacks_interrupted] + _shooter_part()


func _shooter_part() -> String:
	if scenario != "Gemischt":
		return ""
	return " · Schüsse %d (Aufladung abgebrochen %d), Projektiltreffer %d" % [shots_fired, charges_interrupted, projectile_hits]
