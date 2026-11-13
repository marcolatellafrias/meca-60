class_name KinematicLabArchetype
extends SeededArchetype

## EL LABORATORIO CINEMÁTICO (13/11/2026) — EXPERIMENTO: el cubo cinemático (KinematicPillar) y cajas sueltas, para
## probar cómo se lleva lo cinemático con lo físico (ver la nota docs/technical/laboratorio-cinematico.md).
##   · LAS CAJAS, UNA CONFIGURACIÓN POR VEZ (la K las cambia): chicas y livianas sueltas, una pila alta de medianas,
##     grandes y pesadas como autos, o una pared de medianas. El usuario: «no las quiero mezcladas, pero sí un toggle con
##     varias configuraciones».
##   · LA FORMA DE INTERACTUAR del cubo con lo suelto (la L): ver KinematicPillar.
##   · LA LLUVIA (la N): cajas de la configuración de ahora caen encima del cubo, donde esté. El usuario: «así vemos como
##     es cuando saltas y te das cosas encima o cuando te agachas y te desagachas».
## Mirándolo, O lo posee.

enum Boxes { SMALL, PILE, CARS, WALL }

const BOX_NAMES := ["chicas y livianas, sueltas", "una pila alta de medianas", "grandes y pesadas (autos)",
	"una pared de medianas"]
## Cada configuración: su tamaño (m) y lo que pesa (kg).
const BOX_KINDS := {
	Boxes.SMALL: {"size": Vector3(0.6, 0.6, 0.6), "mass": 30.0},
	Boxes.PILE: {"size": Vector3(1.6, 1.6, 1.6), "mass": 300.0},
	Boxes.CARS: {"size": Vector3(2.0, 1.6, 4.2), "mass": 1500.0},
	Boxes.WALL: {"size": Vector3(1.6, 1.6, 1.6), "mass": 300.0},
}
const FOOTPRINT := 110.0
## Dónde nace el cubo y dónde van las cajas (adelante de él).
const START := Vector3(0.0, 0.0, 22.0)
const BOXES_AT := Vector3(0.0, 0.0, -4.0)
## La lluvia: cuántas caen y desde cuán alto sobre el cubo (m).
const RAIN := 6
const RAIN_HEIGHT := 10.0

static var boxes := Boxes.PILE


func _init() -> void:
	display_name = "Laboratorio cinemático"


func max_footprint() -> Vector2:
	return Vector2(FOOTPRINT, FOOTPRINT)


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"EXPERIMENTO: un cubo cinemático hasta el piso, contra cajas sueltas",
		"K las cajas · L cómo trata lo suelto · N lluvia de cajas encima · O poseerlo",
		"poseído: WASD, mouse gira, Shift corre, Ctrl se agacha, espacio salta",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Laboratorio"
	parent.add_child(root)
	var pillar := KinematicPillar.new()
	pillar.name = "Cubo"
	pillar.position = START
	pillar.mode = _mode_now as KinematicPillar.Mode
	root.add_child(pillar)
	var holder := Node3D.new()
	holder.name = "Cajas"
	root.add_child(holder)
	KinematicLabArchetype.lay_out(holder, boxes)
	return root


## LAS CAJAS de la configuración `which`, en `holder` (borra las que había).
static func lay_out(holder: Node3D, which: Boxes) -> void:
	for old in holder.get_children():
		old.queue_free()
	var kind: Dictionary = BOX_KINDS[which]
	var size: Vector3 = kind["size"]
	var random := RandomNumberGenerator.new()
	random.seed = 7
	match which:
		Boxes.SMALL:
			for i in 40:
				KinematicLabArchetype.box(holder, BOXES_AT + Vector3(random.randf_range(-8, 8), size.y * 0.5,
					random.randf_range(-8, 8)), which, random.randf() * TAU)
		Boxes.PILE:
			for i in 24:
				var x := (i % 2) * (size.x + 0.05) - size.x * 0.5
				var z := (floori(i / 2.0) % 2) * (size.z + 0.05) - size.z * 0.5
				KinematicLabArchetype.box(holder, BOXES_AT + Vector3(x, size.y * 0.5 + floori(i / 4.0) * size.y, z), which, 0.0)
		Boxes.CARS:
			for i in 6:
				KinematicLabArchetype.box(holder, BOXES_AT + Vector3((i % 3 - 1) * 7.0, size.y * 0.5,
					floori(i / 3.0) * 8.0 - 4.0), which, random.randf_range(-0.4, 0.4))
		Boxes.WALL:
			for i in 40:
				var x := (i % 8 - 3.5) * (size.x + 0.02)
				KinematicLabArchetype.box(holder, BOXES_AT + Vector3(x, size.y * 0.5 + floori(i / 8.0) * size.y, 0.0), which, 0.0)


## UNA CAJA de la configuración `which` en `at`, girada `yaw`.
static func box(holder: Node3D, at: Vector3, which: Boxes, yaw: float) -> RigidBody3D:
	var kind: Dictionary = BOX_KINDS[which]
	var made := RigidBody3D.new()
	made.mass = kind["mass"]
	holder.add_child(made)
	made.global_transform = Transform3D(Basis(Vector3.UP, yaw), holder.global_transform * at)
	var colors := [Clay.YELLOW, Clay.YELLOW.darkened(0.2), Clay.RED.lightened(0.1), Clay.YELLOW.darkened(0.35)]
	Clay.solid(made, kind["size"], Vector3.ZERO, colors[which])
	return made


## LA LLUVIA: cajas de la configuración de ahora, arriba del cubo.
static func rain(holder: Node3D, pillar: KinematicPillar, which: Boxes) -> void:
	var random := RandomNumberGenerator.new()
	random.randomize()
	var top := pillar.global_position + Vector3.UP * (pillar.height + RAIN_HEIGHT)
	for i in RAIN:
		var at := top + Vector3(random.randf_range(-2.5, 2.5), i * 2.5, random.randf_range(-2.5, 2.5))
		KinematicLabArchetype.box(holder, holder.global_transform.affine_inverse() * at, which, random.randf() * TAU)


func keys() -> Array[SandboxKey]:
	return [
		SandboxKey.cycle(KEY_K, SandboxKey.Weight.MAIN, "cajas", BOX_NAMES, func() -> int: return int(boxes),
			func(parcel: SandboxParcel, index: int) -> void:
				boxes = index as Boxes
				for holder in _holders(parcel):
					KinematicLabArchetype.lay_out(holder, boxes)),
		SandboxKey.cycle(KEY_L, SandboxKey.Weight.MAIN, "con lo suelto", KinematicPillar.MODE_NAMES, _mode,
			func(parcel: SandboxParcel, index: int) -> void:
				_mode_now = index
				for pillar: KinematicPillar in parcel.find_children("*", "KinematicPillar", true, false):
					pillar.mode = index as KinematicPillar.Mode),
		SandboxKey.action(KEY_N, SandboxKey.Weight.MAIN, "lluvia de cajas encima del cubo",
			func(parcel: SandboxParcel) -> void:
				for pillar: KinematicPillar in parcel.find_children("*", "KinematicPillar", true, false):
					for holder in _holders(parcel):
						KinematicLabArchetype.rain(holder, pillar, boxes)),
	]


static var _mode_now := 0


func _mode() -> int:
	return _mode_now


func entered(parcel: SandboxParcel, inside: bool) -> void:
	if not inside:
		return
	for pillar: KinematicPillar in parcel.find_children("*", "KinematicPillar", true, false):
		_mode_now = int(pillar.mode)


static func _holders(parcel: SandboxParcel) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for node in parcel.find_children("Cajas", "Node3D", true, false):
		out.append(node as Node3D)
	return out
