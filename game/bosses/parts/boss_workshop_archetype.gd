class_name BossWorkshopArchetype
extends SeededArchetype

## EL TALLER DE JEFES (17/11/2026): la parcela para armar cuerpos de jefes con piezas (BossParts, BossRecipe, BossFrame)
## y ver qué encaja. ADELANTE, EL QUE SE ARMA: cada tecla cambia una pieza (J las piernas, K el torso, L los brazos, H
## los brazos del segundo par, P la cabeza), y su cartel dice qué lleva, SI ENCAJA (y por qué no) y LO QUE OFRECE a los
## poderes: sus puntos y sus zonas de golpe, por nombre. ATRÁS, EJEMPLOS ya armados. Todo de arcilla y quieto: el groundwork (el
## usuario: «ir haciendo el groundwork para ver qué cosas se pueden combinar con qué»).

const GROUP := "boss_workshop"
## Los ejemplos de atrás.
const EXAMPLES := [
	["orugas", "ancho", "puno", "visor", ""],
	["bipedo", "angosto", "pinza", "antena", ""],
	["cuatro", "cuatro", "canon", "visor", "pinza"],
	["flotante", "ancho", "escudo", "ninguna", ""],
	["cuatro", "ancho", "escudo", "antena", ""],
]

## El que se arma (lo cambian las teclas).
static var recipe := BossRecipe.of("orugas", "ancho", "puno", "visor", "pinza")


func _init() -> void:
	display_name = "Taller de jefes"


func max_footprint() -> Vector2:
	return Vector2(260.0, 200.0)


func far_height() -> float:
	return 30.0


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"armar el cuerpo de un jefe con piezas: piernas, torso, brazos y cabeza",
		"el cartel dice si encaja (el tamaño de los hombros)",
		"y qué ofrece a los poderes: sus puntos (de dónde sale algo) y sus zonas de golpe",
		"J piernas · K torso · L brazos · H brazos del segundo par · P cabeza · F7 la escala de todos",
	])


func keys() -> Array[SandboxKey]:
	return [
		_key(KEY_J, "las piernas", BossParts.Kind.LEGS, "legs"),
		_key(KEY_K, "el torso", BossParts.Kind.TORSO, "torso"),
		_key(KEY_L, "los brazos", BossParts.Kind.ARM, "arm"),
		_key(KEY_H, "los brazos del segundo par", BossParts.Kind.ARM, "arm_b"),
		_key(KEY_P, "la cabeza", BossParts.Kind.HEAD, "head"),
	]


## Una tecla que pasa por las piezas de `kind` y la pone en `field` de la receta.
func _key(key: Key, label: String, kind: BossParts.Kind, field: String) -> SandboxKey:
	var ids: Array = BossParts.of(kind).keys()
	var names := []
	for id: String in ids:
		names.append(BossParts.of(kind)[id]["title"])
	return SandboxKey.cycle(key, SandboxKey.Weight.MAIN, label, names,
		func() -> int: return maxi(ids.find(recipe.get(field)), 0),
		func(_parcel: SandboxParcel, index: int) -> void:
			recipe.set(field, ids[index])
			BossWorkshopArchetype.refresh())


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Taller de jefes"
	parent.add_child(root)
	var stand := _stand(root, Vector3(0.0, 0.0, -20.0), recipe, true)
	stand.add_to_group(GROUP)
	for index in EXAMPLES.size():
		var each: Array = EXAMPLES[index]
		var x := (index - (EXAMPLES.size() - 1) * 0.5) * 48.0
		_stand(root, Vector3(x, 0.0, -75.0), BossRecipe.of(each[0], each[1], each[2], each[3], each[4]), false)
	return root


## Rearma el que se arma (después de una tecla).
static func refresh() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	for stand: Node3D in tree.get_nodes_in_group(GROUP):
		(stand.get_node("Armazón") as BossFrame).build(recipe)
		BossWorkshopArchetype.write(stand.get_node("Cartel") as Label3D, recipe, true)


## UN PUESTO: el armazón de `made` en `at`, mirando al que entra, con su cartel.
func _stand(root: Node3D, at: Vector3, made: BossRecipe, big: bool) -> Node3D:
	var stand := Node3D.new()
	stand.position = at
	root.add_child(stand)
	var frame := BossFrame.new()
	frame.name = "Armazón"
	frame.rotation.y = PI
	stand.add_child(frame)
	frame.build(made)
	var label := Label3D.new()
	label.name = "Cartel"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 120 if big else 80
	label.width = 2600.0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.outline_size = 50
	label.pixel_size = 0.02
	label.no_depth_test = true
	label.position = Vector3(0.0, 30.0 if big else 26.0, 0.0)
	stand.add_child(label)
	BossWorkshopArchetype.write(label, made, big)
	return stand


## EL CARTEL: qué lleva, si encaja, lo que le dan sus piezas y qué poderes podría usar.
static func write(label: Label3D, made: BossRecipe, full: bool) -> void:
	var problems := made.problems()
	var lines := PackedStringArray([made.title()])
	if problems.is_empty():
		lines.append("ENCAJA")
	else:
		for problem in problems:
			lines.append("NO ENCAJA: " + problem)
	if full:
		lines.append("puntos: " + ", ".join(made.points()))
		lines.append("zonas de golpe: " + ", ".join(made.zones()))
		lines.append("en el piso" if made.gives().has("suelo") else "no pisa: sólo poderes que no pidan suelo")
	label.text = "\n".join(lines)
	label.modulate = Color(1, 1, 1) if problems.is_empty() else Color(1.0, 0.5, 0.4)
