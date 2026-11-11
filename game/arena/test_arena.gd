class_name TestArena
extends Node3D

## LA ARENA DE PRUEBA: un redondel de 160 m con unos edificios alrededor para cubrirse y medir la escala, la meca en
## un lado y la meca rival en el otro, mirándose. No es la ciudad del taxi: es un lugar hecho para las peleas.
## Los edificios salen de la semilla; las mecas, siempre en el mismo lugar.
##
## EL RIVAL es una meca igual, sin piloto (MechBrain): quieto, es una bolsa de arena; agresivo, pelea (N cambia). Las
## dos mecas no se atraviesan: si se pisan, se separan (no se pueden quedar abrazadas).

const RADIUS := 80.0
const FLOOR_COLOR := Color(0.6, 0.58, 0.53)
const LINE_COLOR := Color(0.45, 0.43, 0.4)
const BUILDING_COLOR := Color(0.7, 0.68, 0.64)
const MECH_START := Vector3(-24.0, 0.0, 0.0)
const RIVAL_START := Vector3(24.0, 0.0, 0.0)
const RIVAL_GLOVES := Color(0.2, 0.4, 0.85)

var mech: Mech = null
var rival: Mech = null
var _seed := 0
var _blocks: Array[Rect2] = []


func build(seed_value: int) -> void:
	_seed = seed_value
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var ground := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = RADIUS
	disc.bottom_radius = RADIUS
	disc.height = 0.02
	disc.radial_segments = 96
	ground.mesh = disc
	ground.material_override = Clay.material(FLOOR_COLOR)
	ground.position.y = 0.012
	add_child(ground)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = RADIUS - 1.0
	torus.outer_radius = RADIUS
	torus.rings = 96
	ring.mesh = torus
	ring.scale = Vector3(1.0, 0.02, 1.0)
	ring.material_override = Clay.material(LINE_COLOR)
	ring.position.y = 0.03
	add_child(ring)
	# LOS EDIFICIOS: en un anillo, salteando el pasillo entre las dos mecas.
	var count := 9
	for i in count:
		var angle := TAU * (float(i) + rng.randf_range(-0.2, 0.2)) / float(count) + 0.35
		if absf(sin(angle)) < 0.25:
			continue
		var distance := rng.randf_range(42.0, 66.0)
		var size := Vector3(rng.randf_range(10.0, 18.0), rng.randf_range(12.0, 34.0), rng.randf_range(10.0, 18.0))
		var at := Vector3(cos(angle) * distance, size.y * 0.5, sin(angle) * distance)
		var building := StaticBody3D.new()
		building.name = "Edificio %d" % i
		add_child(building)
		Clay.solid(building, size, at, BUILDING_COLOR.darkened(rng.randf_range(0.0, 0.2)))
		_blocks.append(Rect2(Vector2(at.x - size.x * 0.5, at.z - size.z * 0.5), Vector2(size.x, size.z)))
		# Ventanas pintadas, para que se lea la escala: una franja por piso de 3,3 m.
		for floor_index in int(size.y / 3.3):
			Clay.box(building, Vector3(size.x + 0.05, 0.6, size.z + 0.05), at + Vector3(0, -size.y * 0.5 + 1.8 + floor_index * 3.3, 0),
				BUILDING_COLOR.darkened(0.45))
	mech = Mech.new()
	mech.name = "Meca"
	mech.position = MECH_START
	# Mirando al rival (+X).
	mech.rotation.y = -PI * 0.5
	mech.can_stand = _free
	add_child(mech)
	rival = Mech.new()
	rival.name = "Meca rival"
	rival.position = RIVAL_START
	rival.rotation.y = PI * 0.5
	rival.glove_color = RIVAL_GLOVES
	rival.can_stand = _free
	rival.brain = MechBrain.new()
	rival.brain.target = mech
	add_child(rival)
	mech.opponent = rival
	rival.opponent = mech


## El rival: quieto o agresivo.
func toggle_rival() -> void:
	rival.brain.mode = MechBrain.Mode.AGGRESSIVE if rival.brain.mode == MechBrain.Mode.STILL else MechBrain.Mode.STILL


## Si una meca puede pararse en `at` (en el mundo) con ese radio: adentro del redondel y lejos de los edificios.
func _free(at: Vector3, radius: float) -> bool:
	var local := to_local(at)
	var flat := Vector2(local.x, local.z)
	if flat.length() > RADIUS - radius:
		return false
	for block in _blocks:
		if block.grow(radius).has_point(flat):
			return false
	return true


## LAS DOS MECAS NO SE PISAN: si quedan más cerca que la suma de sus radios, cada una se corre la mitad (si puede).
func _physics_process(_delta: float) -> void:
	if mech == null or rival == null:
		return
	var apart := rival.global_position - mech.global_position
	apart.y = 0.0
	var distance := apart.length()
	var least := Mech.RADIUS * 2.0
	if distance >= least:
		return
	var away := apart / distance if distance > 0.01 else Vector3.RIGHT
	var shove := away * (least - distance) * 0.5
	for pair: Array in [[rival, shove], [mech, -shove]]:
		var who: Mech = pair[0]
		var next: Vector3 = who.global_position + (pair[1] as Vector3)
		if _free(next, Mech.RADIUS):
			who.global_position = next
