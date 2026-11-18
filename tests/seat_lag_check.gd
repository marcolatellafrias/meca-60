extends Node

## LAS SILLAS DE LA MECA JAULA, ¿VAN CLAVADAS? (18/11/2026, el usuario: «las sillas deberían estar totalmente atornilladas a
## la meca… cuando… se quedan atrás… me refiero más bien a su origen»). La meca con sus maniquíes sentados camina a fondo
## y tira un dash; en cada paso (después de todo lo demás) y en cada cuadro se mide, para cada silla, cuánto se corre
## respecto de la meca: la silla, la silla que se ve (la del ocupante, si la lleva) y el que está sentado. Clavadas, 0.
##   tools/godot_ventana.sh res://tests/seat_lag_check.tscn

var _mech: CageMech = null
var _rest := {}
var _worst := {}
var _measuring := false


func _ready() -> void:
	process_physics_priority = 10000
	process_priority = 10000
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var holder := Node3D.new()
	add_child(holder)
	CageMechArchetype.new().build(0, holder)
	for found in holder.find_children("*", "CageMech", true, false):
		if found.arms_kind != Mech.Arms.NONE:
			_mech = found
	await get_tree().create_timer(2.0).timeout
	# EN LA DE ABAJO, COMO EN EL SANDBOX: el ente (se mueve directo, sin cuerpo a la vista) en lugar del maniquí.
	var cabin := _mech.cabin as CageCabin
	cabin.evict(CageCabin.DRIVER)
	var ente := (load(MechCabin.DUMMY_SCENE) as PackedScene).instantiate() as BoneInstantiator
	ente.kind = CharacterKind.ente()
	holder.add_child(ente)
	_mech.add_collision_exception_with(ente.char_rigidbody)
	var chair := cabin.chairs[CageCabin.DRIVER]
	ente.place_at(chair.global_position + chair.global_basis.z * 0.8, chair.heading())
	await get_tree().create_timer(0.5).timeout
	# Como lo sienta la silla al jugador local (a éste no lo encuentra como tal: ver SeatInteractable._local_player).
	chair.call("_sit", ente)
	await get_tree().create_timer(1.5).timeout
	print("EN LA DE ABAJO, EL ENTE: sentado ", ente.is_seated)
	for chair_now in _mech.cabin.chairs:
		_rest[chair_now] = _sample(chair_now)
	_measuring = true
	var cockpit := (_mech.keys as ToolMechKeys).cockpit
	cockpit.move = Vector2(0.0, 1.0)
	await get_tree().create_timer(1.5).timeout
	print("CAMINANDO a ", snappedf(_mech.mover.velocity.length(), 0.1), " m/s:")
	_report()
	cockpit.dash_way = Vector2(1.0, 0.0)
	cockpit.dash = true
	await get_tree().create_timer(0.4).timeout
	cockpit.dash = false
	cockpit.move = Vector2.ZERO
	await get_tree().create_timer(0.5).timeout
	print("CON EL DASH:")
	_report()
	# EL GIRO: el torso persigue 90° a la derecha con su resorte, quieta y caminando.
	for walking: bool in [false, true]:
		cockpit.move = Vector2(0.0, 1.0) if walking else Vector2.ZERO
		var aim := _mech.global_rotation.y - PI * 0.5
		for i in Engine.physics_ticks_per_second * 2:
			_mech.steer(aim, 0.0)
			await get_tree().physics_frame
		print("GIRANDO 90°", " CAMINANDO" if walking else " QUIETA", ":")
		_report()
	cockpit.move = Vector2.ZERO
	get_tree().quit()


## Dónde están, desde la meca: la silla, la silla que se ve y el que está sentado.
func _sample(chair: SeatInteractable) -> Array:
	var shown: Node3D = chair.get("_borrowed_mesh") if is_instance_valid(chair.get("_borrowed_mesh")) \
		else chair.get("_visual_root")
	var sitter: Node = chair.get("_seated_bi")
	var body: Node3D = sitter.get("char_rigidbody") if is_instance_valid(sitter) else null
	return [_mech.to_local(chair.global_position),
		_mech.to_local(shown.global_position) if is_instance_valid(shown) else Vector3.ZERO,
		_mech.to_local(body.global_position) if is_instance_valid(body) else Vector3.ZERO,
		is_instance_valid(sitter)]


func _physics_process(_delta: float) -> void:
	_measure("paso")


func _process(_delta: float) -> void:
	_measure("cuadro")


func _measure(when: String) -> void:
	if not _measuring:
		return
	for chair: SeatInteractable in _rest:
		var now := _sample(chair)
		var then: Array = _rest[chair]
		for k in 3:
			var key := "%s|%s|%d" % [chair.name, when, k]
			_worst[key] = maxf(float(_worst.get(key, 0.0)), (now[k] as Vector3).distance_to(then[k]))


func _report() -> void:
	for chair: SeatInteractable in _rest:
		var line := PackedStringArray()
		for when: String in ["paso", "cuadro"]:
			var parts := PackedStringArray()
			for k in 3:
				parts.append("%.2f" % float(_worst.get("%s|%s|%d" % [chair.name, when, k], 0.0)))
			line.append("%s: silla %s · la que se ve %s · el sentado %s" % [when, parts[0], parts[1], parts[2]])
		print("  ", chair.name, (" (ocupada)" if (_rest[chair] as Array)[3] else " (vacía)"), " — ", " | ".join(line))
	_worst.clear()
