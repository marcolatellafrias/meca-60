class_name KinematicMechArchetype
extends SeededArchetype

## LA PARCELA DE LA MECA CINEMÁTICA (13/11/2026) — MAQUETA (ver KinematicMech): la caja abierta arriba, con TRES CUBOS
## ADENTRO en su marco —dos llevados como la gente, que no sienten la inercia, y uno rojo que la siente entera— y una
## PILA DE CUBOS AFUERA, adelante (se ve qué les hace al empujarlos). Para mirarla de adentro: U te sube, y K hace la rutina (camina, salta, dash, media vuelta, corre y
## frena) mientras mirás. O la posee.

const FOOTPRINT := 140.0
## Los cubos: su lado (m) y lo que pesan (kg).
const CUBE := 1.6
const CUBE_MASS := 300.0


func _init() -> void:
	display_name = "Meca cinemática"


func max_footprint() -> Vector2:
	return Vector2(FOOTPRINT, FOOTPRINT)


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"MAQUETA: la meca sin física de Jolt; el péndulo lo calcula ella y se pone donde calculó",
		"adentro, dos cubos llevados como la gente y uno rojo que siente la inercia; afuera, una pila para empujar",
		"U subirse · K la rutina (salto, dash, media vuelta, correr y frenar) · N / M pegarle · O poseerla",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Meca cinemática"
	parent.add_child(root)
	var mech := KinematicMech.new()
	mech.name = "Meca"
	mech.position = Vector3(0.0, BodySettings.current.hover_height + KinematicMech.SIZE.y * 0.5, 30.0)
	root.add_child(mech)
	var floor_y := -KinematicMech.SIZE.y * 0.5 + KinematicMech.WALL + CUBE * 0.5
	# Dos llevados como la gente (no sienten la inercia) y uno suelto, que la siente entera (el rojo).
	for x: float in [-2.5, 0.0, 2.5]:
		var cube := _cube(root, mech.global_transform * Vector3(x, floor_y, x * 0.6), x > 1.0)
		mech.carry(cube, 1.0 if x > 1.0 else 0.0)
	# La pila, alta: la caja va a la altura de la cintura (7 m) y pasa por arriba de lo bajo.
	for i in 12:
		_cube(root, Vector3((i % 2) * CUBE * 1.05 - CUBE * 0.5, CUBE * 0.5 + floor(i / 2.0) * CUBE, 21.0), false)
	return root


func _cube(root: Node3D, at: Vector3, loose: bool) -> RigidBody3D:
	var cube := RigidBody3D.new()
	cube.name = "Cubo"
	cube.mass = CUBE_MASS
	root.add_child(cube)
	cube.global_position = at
	Clay.solid(cube, Vector3.ONE * CUBE, Vector3.ZERO, Clay.RED if loose else Clay.YELLOW.darkened(0.2))
	return cube


func keys() -> Array[SandboxKey]:
	return [
		SandboxKey.action(KEY_K, SandboxKey.Weight.MAIN, "la rutina: salto, dash, media vuelta, correr y frenar",
			func(parcel: SandboxParcel) -> void: _each(parcel, func(mech: KinematicMech) -> void: mech.routine())),
		SandboxKey.action(KEY_U, SandboxKey.Weight.MAIN, "subirse (atrás del medio)",
			func(parcel: SandboxParcel) -> void: _each(parcel, func(mech: KinematicMech) -> void: _board(mech))),
		SandboxKey.action(KEY_N, SandboxKey.Weight.NORMAL, "pegarle suave",
			func(parcel: SandboxParcel) -> void: _each(parcel, func(mech: KinematicMech) -> void: mech.knock(false))),
		SandboxKey.action(KEY_M, SandboxKey.Weight.NORMAL, "pegarle fuerte",
			func(parcel: SandboxParcel) -> void: _each(parcel, func(mech: KinematicMech) -> void: mech.knock(true))),
	]


static func _board(mech: KinematicMech) -> void:
	var player := DesignSandbox.player_of(mech.get_tree())
	if player == null:
		return
	player.place_at(mech.global_transform * Vector3(0.0, -KinematicMech.SIZE.y * 0.5 + KinematicMech.WALL + 0.05, 3.0),
		mech.global_rotation.y)


static func _each(parcel: SandboxParcel, action: Callable) -> void:
	for mech: KinematicMech in parcel.find_children("*", "KinematicMech", true, false):
		action.call(mech)
