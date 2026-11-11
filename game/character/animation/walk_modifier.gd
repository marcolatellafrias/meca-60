class_name WalkModifier
extends Resource

## ── LOS MODIFICADORES DE CAMINATA, POSE Y QUIETO ─────────────────────────────────────────────────
## Lo pidió el dios del juego (12/10/2026): modificadores que se le aplican a los personajes y que SE SUMAN —varios en
## uno—, en cuatro categorías para probar combinaciones: las PIERNAS (saltarín, zancos largos…), el TREN SUPERIOR
## (contoneo, rígido…), la POSE (encorvado, tirado atrás…) y QUIETO (temblando, respirando rápido…).
##
## Un modificador es una lista de cambios sobre números con nombre: cada uno se MULTIPLICA (`mul`) y después se le SUMA
## (`add`). Si el número es de la caminata (WalkStyle), cambia en vivo, sobre la base que se tweakea con F3; si es del
## arquetipo —la pose, la respiración, el temblor (EntityArchetype)— o del equilibrio del cuerpo (CharacterRigidBody3D), cambia
## al nacer el personaje (ver BoneInstantiator.walk_modifiers). Varios se aplican en orden, uno sobre otro.

enum Category { LEGS, UPPER, POSE, IDLE }
const CATEGORY_NAMES := ["piernas", "tren superior", "pose", "quieto"]

@export var name := ""
@export var category := Category.LEGS
@export var mul := {}
@export var add := {}


static func make(p_name: String, p_category: Category, p_mul: Dictionary, p_add := {}) -> WalkModifier:
	var out := WalkModifier.new()
	out.name = p_name
	out.category = p_category
	out.mul = p_mul
	out.add = p_add
	return out


## LO QUE LE HACE a `target`: a cada número que tenga, el suyo.
func apply(target: Object) -> void:
	for prop: String in _props():
		if not prop in target:
			continue
		var value := float(target.get(prop)) * float(mul.get(prop, 1.0)) + float(add.get(prop, 0.0))
		target.set(prop, value)


func _props() -> Array:
	var out := mul.keys()
	for prop in add.keys():
		if not out.has(prop):
			out.append(prop)
	return out


## (La caminata de un personaje con modificadores la arma WalkStyle.for_archetype: lo de su arquetipo y éstos encima.
## *Hasta el 07/11/2026 era `compose`, sobre la base de todos, rearmada en cada cuadro.*)


## ── EL CATÁLOGO ──────────────────────────────────────────────────────────────────────────────────
## Los de la primera tanda, elegidos por el dios del juego. El saltarín, en variaciones «dependiendo del ritmo y cómo
## da el paso».
static func catalogue() -> Array[WalkModifier]:
	var C := Category
	var out: Array[WalkModifier] = [
		make("Saltarín, al trote", C.LEGS, {"step_height": 1.4, "stride_scale": 1.11},
			{"bounce_up": 0.04, "swing_share": 0.08}),
		make("Saltarín, de puntas", C.LEGS, {"step_height": 1.8, "swing_share": 0.8, "stride_scale": 0.87,
			"lead": 0.6}, {"bounce_up": 0.03}),
		make("Saltarín, a los saltos", C.LEGS, {"stride_scale": 1.33},
			{"bounce_up": 0.06, "swing_share": 0.15}),
		make("Zancos largos", C.LEGS, {"stride_scale": 1.43,
			"step_height": 0.8, "lead": 1.3}),
		make("Pasitos cortos", C.LEGS, {"stride_scale": 0.62,
			"step_height": 0.7}),
		make("Arrastrando los pies", C.LEGS, {"step_height": 0.15, "swing_share": 0.8, "bounce_down": 0.3}),
		make("Contoneo", C.UPPER, {"hip_sway": 2.2, "spine_bow": 2.2, "twist": 1.8}),
		make("Rígido", C.UPPER, {"twist": 0.1, "hip_sway": 0.2, "spine_bow": 0.2, "arm_swing": 0.1, "shoulders": 0.1}),
		make("Braceo amplio", C.UPPER, {"arm_swing": 2.2, "shoulders": 1.3}),
		make("Hombros que rebotan", C.UPPER, {"shoulders": 2.5}, {"bounce_up": 0.015}),
		make("Tirado adelante", C.POSE, {}, {"posture_lean": 0.18, "slouch": 0.3}),
		make("Piernas abiertas", C.POSE, {"stance_width": 1.8}),
		make("Hombros atrás", C.POSE, {}, {"shoulders_forward": -0.8}),
		make("Encorvado", C.POSE, {}, {"spine_bend": 0.8, "slouch": 0.6, "shoulders_forward": 0.5}),
		make("Tirado atrás", C.POSE, {}, {"posture_lean": -0.15}),
		# (Temblando y Respirando rápido se fueron el 07/11/2026: son perillas de cada arquetipo, en la Pose del F3.)
		# EL EBRIO: el equilibrio del cuerpo (ver CharacterRigidBody3D, EL EBRIO) flojo —resorte blando, poco
		# amortiguamiento: rebota— y que deriva solo; además, el paso desparejo.
		make("Ebrio", C.IDLE, {"impact_stiffness": 0.15, "impact_damping": 0.35, "swing_share": 1.15, "hip_sway": 1.6},
			{"balance_drift": 2.5, "balance_correct_at": 0.45, "spine_bow": 0.6}),
	]
	return out


static func of_category(category: Category) -> Array[WalkModifier]:
	var out: Array[WalkModifier] = []
	for modifier in catalogue():
		if modifier.category == category:
			out.append(modifier)
	return out
