class_name BossFrame
extends Node3D

## EL ARMAZÓN DE UN JEFE (17/11/2026): monta las piezas de una receta (BossRecipe, BossParts) una sobre otra: las
## piernas en el piso, el torso en la cadera, un brazo en cada hombro y la cabeza arriba. Va a la escala de todos los
## jefes (BossSettings). Es sólo el cuerpo: sus piezas, dónde quedaron y SUS ZONAS DE GOLPE por nombre (`hit_shapes`,
## como las del Luchador: "cuerpo", "puños", "brazos"), que los poderes prenden. *Hoy lo usa el Taller de jefes; el
## Luchador todavía es un cuerpo hecho a mano, y pasa a este cuando su cabeza sea la común.*
## LAS PATAS CAMINAN (18/11/2026): las piernas «patas» (dos o cuatro) son BossLegs, en el esqueleto común, con la
## marcha y la IK comunes. Caminan solas con lo que se mueva el armazón (`_physics_process` mide su velocidad): quien lo
## mueva (el Taller, una prueba, más adelante su cabeza) no tiene que decirles nada.

var recipe: BossRecipe = null
## Las piezas montadas: el torso (gira aparte: la cintura), cada hombro y la punta de cada brazo.
var waist: Node3D = null
var shoulders: Array[Node3D] = []
var tips: Array[Node3D] = []

var _fitted := -1.0
## Las patas que caminan (o null: orugas, flotante), y dónde estaba el armazón el paso anterior.
var walking: BossLegs = null
var _was := Vector3.INF


## LO ARMA (o lo rearma) con `made`.
func build(made: BossRecipe) -> void:
	recipe = made
	for child in get_children():
		child.queue_free()
	shoulders.clear()
	tips.clear()
	var legs := Node3D.new()
	legs.name = "Piernas"
	add_child(legs)
	BossParts.draw_legs(legs, recipe.legs)
	walking = null
	if BossParts.LEGS[recipe.legs].has("walk"):
		walking = BossLegs.new()
		walking.name = "Patas"
		add_child(walking)
	_was = Vector3.INF
	waist = Node3D.new()
	waist.name = "Torso"
	waist.position.y = BossParts.LEGS[recipe.legs]["hip"]
	add_child(waist)
	var mounts := BossParts.draw_torso(waist, recipe.torso)
	var arms := recipe.arms()
	for index in arms.size():
		var mount: Array = mounts["shoulders"][index]
		var shoulder := Node3D.new()
		shoulder.name = "Hombro"
		shoulder.position = mount[0]
		waist.add_child(shoulder)
		var tip := Node3D.new()
		tip.name = "Punta"
		tip.position = BossParts.draw_arm(shoulder, arms[index], float(mount[1]))
		shoulder.add_child(tip)
		shoulders.append(shoulder)
		tips.append(tip)
	var head := Node3D.new()
	head.name = "Cabeza"
	head.position = mounts["head"]
	waist.add_child(head)
	BossParts.draw_head(head, recipe.head)
	_fitted = -1.0


func _process(_delta: float) -> void:
	var size := BossSettings.current.scale
	if not is_equal_approx(_fitted, size):
		_fitted = size
		scale = Vector3.ONE * size


## LAS PATAS, CADA PASO: el armazón en el piso (sin escala) y su velocidad, medida de cuánto se movió.
func _physics_process(delta: float) -> void:
	if walking == null:
		return
	var size := BossSettings.current.scale
	if not walking.built(recipe.legs, size):
		walking.build(recipe.legs, size)
	var at := global_position
	var velocity := Vector3.ZERO if _was == Vector3.INF or delta <= 0.0 else (at - _was) / delta
	_was = at
	walking.step(delta, Transform3D(Basis(global_basis.get_rotation_quaternion()), at), velocity)


## Lo alto que es, a escala (m).
func height() -> float:
	var torso: Vector3 = BossParts.TORSOS[recipe.torso]["size"]
	return (float(BossParts.LEGS[recipe.legs]["hip"]) + 3.0 + torso.y + 3.0) * BossSettings.current.scale


## SUS ZONAS DE GOLPE por nombre, ahora, en el mundo: cada una [desde, hasta, radio]. "cuerpo" (el torso entero),
## "brazos" (cada brazo, del hombro a la punta) y "puños" (la punta de cada brazo).
func hit_shapes(part: String) -> Array:
	var shapes := []
	var size := BossSettings.current.scale
	match part:
		"cuerpo":
			var torso: Vector3 = BossParts.TORSOS[recipe.torso]["size"]
			var middle := waist.global_position + Vector3.UP * (3.0 + torso.y * 0.5) * size
			shapes.append([middle, middle + Vector3.UP * 0.01, maxf(torso.x, torso.z) * 0.5 * size])
		"brazos":
			for index in tips.size():
				shapes.append([shoulders[index].global_position, tips[index].global_position, 2.2 * size])
		"puños":
			for tip in tips:
				shapes.append([tip.global_position, tip.global_position, 3.0 * size])
	return shapes
