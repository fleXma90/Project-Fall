class_name RunState
extends RefCounted
## Zustand eines Abstiegs-Runs (M3A): Level, XP, Attributspunkte/-ränge, Floor-Upgrades und der
## seedbare Zufallsgenerator für die Upgrade-Auswahl. Gehört genau einem DESCENT-Run; ein neuer Run
## erzeugt eine neue Instanz (kein Übertrag, keine Speicherung, keine Meta-Progression).
##
## Effektive Werte werden nie gespeichert oder aufmultipliziert, sondern jederzeit aus Basisdaten und
## diesem Zustand berechnet. Reihenfolge je Wert: Basis × Attributfaktor × Upgradefaktor (bzw. + Bonus).

signal xp_changed(current_xp: int, xp_to_next: int, level: int)
## Ein XP-Ereignis hat levels Level-Ups ausgelöst (je +1 Attributspunkt).
signal leveled_up(levels: int, level: int)
signal attributes_changed
signal upgrades_changed

const POWER: StringName = &"power"
const VITALITY: StringName = &"vitality"
const HASTE: StringName = &"haste"
const AGILITY: StringName = &"agility"
const IMPACT: StringName = &"impact"
const RECOVERY: StringName = &"recovery"
const ATTRIBUTES: Array[StringName] = [POWER, VITALITY, HASTE, AGILITY, IMPACT, RECOVERY]
const MAX_RANK: int = 8

## Pro Rang (Prototypwerte, siehe docs/RUN_PROGRESSION.md).
const POWER_PER_RANK: float = 0.05
const VITALITY_HP_PER_RANK: float = 10.0
const HASTE_PER_RANK: float = 0.03
const AGILITY_PER_RANK: float = 0.025
const IMPACT_PER_RANK: float = 0.06
const RECOVERY_PER_RANK: float = 0.04

const DENSE_HEAD: StringName = &"dense_head"
const HEAVY_IMPACT: StringName = &"heavy_impact"
const WIDE_SWING: StringName = &"wide_swing"
const LONG_GRIP: StringName = &"long_grip"
const MOMENTUM_CORE: StringName = &"momentum_core"
const KINETIC_RECOVERY: StringName = &"kinetic_recovery"
const UPGRADES: Array[StringName] = [DENSE_HEAD, HEAVY_IMPACT, WIDE_SWING, LONG_GRIP, MOMENTUM_CORE, KINETIC_RECOVERY]

const DENSE_HEAD_DAMAGE: float = 1.15
const HEAVY_IMPACT_KNOCKBACK: float = 1.30
const WIDE_SWING_ARC: float = 25.0
const LONG_GRIP_RANGE: float = 0.25
const MOMENTUM_SPEED: float = 1.20
const MOMENTUM_DURATION: float = 1.5
const KINETIC_DODGE_REFUND: float = 0.20

var player_level: int = 1
var current_xp: int = 0
var total_xp: int = 0
var unspent_attribute_points: int = 0
var ranks: Dictionary = {}
var upgrades: Array[StringName] = []
var rng := RandomNumberGenerator.new()


## seed_value 0 = zufällig; Tests setzen einen festen Seed.
func _init(seed_value: int = 0) -> void:
	for attribute in ATTRIBUTES:
		ranks[attribute] = 0
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()


static func xp_to_next(level: int) -> int:
	return 60 + 30 * (level - 1)


## XP gutschreiben (inkl. Übertrag und mehrerer Level-Ups). Gibt die Zahl der Level-Ups zurück.
func add_xp(amount: int) -> int:
	if amount <= 0:
		return 0
	current_xp += amount
	total_xp += amount
	var levels := 0
	while current_xp >= xp_to_next(player_level):
		current_xp -= xp_to_next(player_level)
		player_level += 1
		unspent_attribute_points += 1
		levels += 1
	xp_changed.emit(current_xp, xp_to_next(player_level), player_level)
	if levels > 0:
		leveled_up.emit(levels, player_level)
	return levels


func rank(attribute: StringName) -> int:
	return int(ranks.get(attribute, 0))


func can_invest(attribute: StringName) -> bool:
	return ranks.has(attribute) and unspent_attribute_points > 0 and rank(attribute) < MAX_RANK


## Genau ein Punkt → genau ein Rang. Kein Respec.
func invest(attribute: StringName) -> bool:
	if not can_invest(attribute):
		return false
	unspent_attribute_points -= 1
	ranks[attribute] = rank(attribute) + 1
	attributes_changed.emit()
	return true


func spent_points() -> int:
	var total := 0
	for attribute in ATTRIBUTES:
		total += rank(attribute)
	return total


func has_upgrade(id: StringName) -> bool:
	return upgrades.has(id)


func add_upgrade(id: StringName) -> bool:
	if not UPGRADES.has(id) or has_upgrade(id):
		return false
	upgrades.append(id)
	upgrades_changed.emit()
	return true


## Bis zu count unterschiedliche, noch nicht besessene Upgrades (weniger, falls der Pool erschöpft ist).
func roll_upgrade_choices(count: int = 3) -> Array[StringName]:
	var available: Array[StringName] = []
	for id in UPGRADES:
		if not has_upgrade(id):
			available.append(id)
	for i in range(available.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := available[i]
		available[i] = available[j]
		available[j] = tmp
	return available.slice(0, mini(count, available.size()))


# --- Effektive Modifikatoren (optional für einen hypothetischen Rang, z. B. Vorschau) ------------

func _r(attribute: StringName, at_rank: int) -> int:
	return rank(attribute) if at_rank < 0 else at_rank


func damage_multiplier(at_rank: int = -1) -> float:
	return (1.0 + POWER_PER_RANK * _r(POWER, at_rank)) * (DENSE_HEAD_DAMAGE if has_upgrade(DENSE_HEAD) else 1.0)


func max_hp_bonus(at_rank: int = -1) -> float:
	return VITALITY_HP_PER_RANK * _r(VITALITY, at_rank)


func attack_speed_multiplier(at_rank: int = -1) -> float:
	return 1.0 + HASTE_PER_RANK * _r(HASTE, at_rank)


func move_multiplier(at_rank: int = -1) -> float:
	return 1.0 + AGILITY_PER_RANK * _r(AGILITY, at_rank)


func knockback_multiplier(at_rank: int = -1) -> float:
	return (1.0 + IMPACT_PER_RANK * _r(IMPACT, at_rank)) * (HEAVY_IMPACT_KNOCKBACK if has_upgrade(HEAVY_IMPACT) else 1.0)


func dodge_cooldown_multiplier(at_rank: int = -1) -> float:
	return 1.0 - RECOVERY_PER_RANK * _r(RECOVERY, at_rank)


func arc_bonus() -> float:
	return WIDE_SWING_ARC if has_upgrade(WIDE_SWING) else 0.0


func range_bonus() -> float:
	return LONG_GRIP_RANGE if has_upgrade(LONG_GRIP) else 0.0


# --- Anzeige ---------------------------------------------------------------------------------

static func attribute_name(attribute: StringName) -> String:
	match attribute:
		POWER:
			return "STÄRKE"
		VITALITY:
			return "VITALITÄT"
		HASTE:
			return "TEMPO"
		AGILITY:
			return "BEWEGLICHKEIT"
		IMPACT:
			return "WUCHT"
		RECOVERY:
			return "ERHOLUNG"
	return String(attribute)


static func upgrade_name(id: StringName) -> String:
	match id:
		DENSE_HEAD:
			return "Verdichteter Hammerkopf"
		HEAVY_IMPACT:
			return "Schwerer Einschlag"
		WIDE_SWING:
			return "Weiter Schwung"
		LONG_GRIP:
			return "Langer Griff"
		MOMENTUM_CORE:
			return "Momentum-Kern"
		KINETIC_RECOVERY:
			return "Kinetische Erholung"
	return String(id)


static func upgrade_description(id: StringName) -> String:
	match id:
		DENSE_HEAD:
			return "+15 % Hammer-Schaden"
		HEAVY_IMPACT:
			return "+30 % Hammer-Knockback"
		WIDE_SWING:
			return "+25° Hammer-Trefferbogen"
		LONG_GRIP:
			return "+0.25 m Hammer-Reichweite"
		MOMENTUM_CORE:
			return "Erster Treffer eines Schwungs:\n+20 % Laufgeschwindigkeit für 1.5 s"
		KINETIC_RECOVERY:
			return "Erster Treffer eines Schwungs:\nDodge-Abklingzeit −0.20 s"
	return ""


func upgrade_names() -> String:
	var names: PackedStringArray = []
	for id in upgrades:
		names.append(upgrade_name(id))
	return ", ".join(names) if not names.is_empty() else "keine"
