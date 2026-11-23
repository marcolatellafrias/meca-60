class_name HitCard
extends RefCounted

## LA FICHA DE UN GOLPE: qué arma fue y cuánto daño, quiebre y empuje lleva (ver HitSettings). `power` la escala: lo cargado
## del cañón (0 a 1), la fuerza de la piña cargada (1 a 2,5), lo que giraba el taladro o la parte de la explosión.

var source := ""
var damage := 0.0
var stagger := 0.0
var push := 0.0


static func make(from: String, power := 1.0) -> HitCard:
	var knobs := HitSettings.current
	var card := HitCard.new()
	card.source = from
	match from:
		"cañón", "rayo":
			card._fill(knobs.cannon_damage, knobs.cannon_stagger, knobs.cannon_push, power)
		"minigun":
			card._fill(knobs.minigun_damage, knobs.minigun_stagger, knobs.minigun_push, power)
		"misil":
			card._fill(knobs.missile_damage, knobs.missile_stagger, knobs.missile_push, power)
		"taladro", "sierra":
			card._fill(knobs.spin_damage, knobs.spin_stagger, knobs.spin_push, power)
		_:
			card._fill(knobs.fist_damage, knobs.fist_stagger, knobs.fist_push, power)
	return card


func _fill(base_damage: float, base_stagger: float, base_push: float, power: float) -> void:
	damage = base_damage * power
	stagger = base_stagger * power
	push = base_push * power
