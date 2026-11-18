class_name LocomotionLab
extends Node3D

## ── UNA ESCENA DE LA FILA LOCOMOCIÓN (ver LocomotionLabArchetype) ──────────────────────────────────────────────────
## Arma el piso, los obstáculos y los seis personajes en carriles, y los hace actuar con una lista de pasos: cada paso
## hace algo (`do`) y espera a que pase algo (`until`) o a que se acabe su tiempo (`max`). Los personajes van de −Z a +Z
## (corren de costado a quien mira desde la entrada de la parcela).
##
## ── DESPIERTA SÓLO CON UNO ADENTRO (17/11/2026, el usuario: «cada vez que paso por arriba de la parcela de locomoción
## se me tilda») ─────────────────────────────────────────────────────────────────────────────────────────────────────
## La escena arma el piso y los obstáculos al toque, pero a las personas recién cuando uno entra a su parcela, DE A UNA
## POR PASO (`_queue`), y los pasos arrancan cuando están todas. Saliendo, lo que vive (`_live`: las personas y los
## cubos) se duerme. *Antes las siete escenas armaban sus 42 personas en un cuadro al acercarse (2,2 s) y seguían
## andando todas aunque uno estuviera en otra.* Fuera del sandbox (las pruebas) nace despierta.

const PEOPLE := PeopleArchetype.ROW_ORDER
## El ancho de un carril (m), y dónde arrancan y adónde van.
const LANE := 1.8
const START_Z := -9.0
const END_Z := 9.0
## Lo que se quedan quietos antes de arrancar (s): que se asienten.
const SETTLE_S := 1.2
## Lo más que espera un paso (s), por si alguien se cae y no llega nunca.
const STEP_MAX := 8.0
const OBSTACLE_COLOR := Color(0.55, 0.53, 0.5)
const WALL_COLOR := Color(0.62, 0.6, 0.57)

var _row: LocomotionLabArchetype
## Lo que vive (las personas y los cubos), lo que falta armar —[arquetipo, lugar, hacia dónde]— y si está despierta.
var _live: Node3D = null
var _queue: Array = []
var _awake := true
var _people: Array[BoneInstantiator] = []
var _cubes: Array[RigidBody3D] = []
var _tags: Array[Label3D] = []
var _steps: Array[Dictionary] = []
var _step_t := 0.0


func setup(row: LocomotionLabArchetype, awake := true) -> void:
	_row = row
	_awake = awake


## DESPIERTA O DORMIDA (ver DESPIERTA SÓLO CON UNO ADENTRO): lo que vive anda o se queda quieto.
func set_awake(on: bool) -> void:
	_awake = on
	if is_instance_valid(_live):
		_live.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


## Si ya están todas sus personas.
func populated() -> bool:
	return _queue.is_empty()


func _ready() -> void:
	_live = Node3D.new()
	_live.name = "Vivos"
	add_child(_live)
	set_awake(_awake)
	match _row.scene:
		LocomotionLabArchetype.Scene.RUN:
			_build_run()
		LocomotionLabArchetype.Scene.JUMP:
			_build_jump()
		LocomotionLabArchetype.Scene.DROP:
			_build_drop()
		LocomotionLabArchetype.Scene.CARRY:
			_build_carry()
		LocomotionLabArchetype.Scene.CATCH:
			_build_catch()
		LocomotionLabArchetype.Scene.SLALOM:
			_build_slalom()


## UNA PERSONA MÁS, la que sigue en la fila, con su cartel de velocidad.
func _spawn_next() -> void:
	var next: Array = _queue.pop_front()
	var bi := PeopleArchetype.spawn(_live, next[0] as EntityArchetype.Archetype, to_global(next[1]),
		0.0 if float(next[2]) < 0.0 else PI)
	_people[int(next[3])] = bi
	CharacterActions.of(bi)
	var tag := Label3D.new()
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.font_size = 48
	tag.pixel_size = 0.004
	tag.outline_size = 10
	tag.no_depth_test = true
	_live.add_child(tag)
	_tags.append(tag)


## ── LOS PASOS ──────────────────────────────────────────────────────────────────────────────────────────────────────
func _step(do: Callable, until := Callable(), at_least := 0.0) -> void:
	_steps.append({"do": do, "until": until, "min": at_least})


func _wait(seconds: float) -> void:
	_steps.append({"do": Callable(), "until": Callable(), "min": seconds})


func _physics_process(delta: float) -> void:
	if not _awake:
		return
	if not _queue.is_empty():
		_spawn_next()
		return
	_update_tags()
	if _steps.is_empty():
		return
	var step: Dictionary = _steps[0]
	if not step.has("started"):
		step["started"] = true
		_step_t = 0.0
		if (step["do"] as Callable).is_valid():
			(step["do"] as Callable).call()
	_step_t += delta
	var until: Callable = step["until"]
	var ready := _step_t >= float(step["min"]) and (not until.is_valid() or bool(until.call()))
	if ready or _step_t >= maxf(STEP_MAX, float(step["min"])):
		_steps.pop_front()


## Todos los que siguen de pie cumplen `test` (los caídos no cuentan: no van a llegar).
func _all(test: Callable) -> Callable:
	return func() -> bool:
		for bi in _people:
			if is_instance_valid(bi) and not bi._is_ragdolling() and not bool(test.call(CharacterActions.of(bi))):
				return false
		return true


func _each(action: Callable) -> Callable:
	return func() -> void:
		for i in _people.size():
			if is_instance_valid(_people[i]):
				action.call(i, CharacterActions.of(_people[i]))


## LA VELOCIDAD DE CADA UNO, arriba de su cabeza: el nombre y los m/s en el plano.
func _update_tags() -> void:
	for i in mini(_tags.size(), _people.size()):
		var bi := _people[i]
		if not is_instance_valid(bi) or not is_instance_valid(bi.char_rigidbody):
			_tags[i].visible = false
			continue
		var rb := bi.char_rigidbody
		var v := rb.get_motion_velocity() if not bi._is_ragdolling() else Vector3.ZERO
		var top := bi.skel_sizes_util.total_height if bi.skel_sizes_util != null else 1.8
		_tags[i].visible = true
		_tags[i].global_position = rb.global_position + Vector3.UP * (top * 0.6 + 0.35)
		_tags[i].text = "%s\n%.1f m/s" % [bi.name, Vector2(v.x, v.z).length()]


## ── LAS PIEZAS ─────────────────────────────────────────────────────────────────────────────────────────────────────
## El medio del carril `i` (en x, local).
static func _lane_x(i: int, count := 6, width := LANE) -> float:
	return (i - (count - 1) * 0.5) * width


## UNA PERSONA, a la fila: se arma recién despierta, de a una por paso (ver DESPIERTA SÓLO CON UNO ADENTRO). Los pasos
## la leen de `_people` cuando ya está.
func _person(archetype: int, at_local: Vector3, facing_z := 1.0) -> void:
	_queue.append([archetype, at_local, facing_z, _people.size()])
	_people.append(null)


func _box(size: Vector3, at_local: Vector3, color := OBSTACLE_COLOR) -> StaticBody3D:
	var body := StaticBody3D.new()
	add_child(body)
	Clay.solid(body, size, at_local, color)
	return body


func _cube(kind: int, at_local: Vector3) -> RigidBody3D:
	var catalogue := PackageArchetype.catalogue()
	var body := (catalogue[kind % catalogue.size()] as PackageArchetype).build_body()
	_live.add_child(body)
	body.global_position = to_global(at_local)
	body.sleeping = false
	_cubes.append(body)
	return body


func _lane_people(z: float, facing_z := 1.0) -> void:
	for i in PEOPLE.size():
		_person(PEOPLE[i], Vector3(_lane_x(i), 0.0, z), facing_z)


func _goal(i: int, z: float) -> Vector3:
	return to_global(Vector3(_lane_x(i), 0.0, z))


## ── CORRER Y FRENAR: aceleran hasta el final del carril y frenan (soltando, apretando para atrás o contra una pared).
func _build_run() -> void:
	_lane_people(START_Z)
	var wall := _row.option_j == 2
	if wall:
		_box(Vector3(_lane_x(5) - _lane_x(0) + LANE, 2.4, 0.4), Vector3(0.0, 1.2, END_Z - 1.0), WALL_COLOR)
	var brake := _row.option_j == 1
	var end := END_Z + 4.0 if wall else END_Z
	_wait(SETTLE_S)
	_step(_each(func(i: int, a: CharacterActions) -> void: a.go_to(_goal(i, end), _row.sprint, brake)),
		_all(func(a: CharacterActions) -> bool: return not a.moving()))


## ── SALTAR: corren hacia una valla en el medio y la saltan; o una viga a la altura de la cabeza, que no ven.
func _build_jump() -> void:
	_lane_people(START_Z)
	var obstacle: Array = LocomotionLabArchetype.JUMP_OBSTACLES[_row.option_j]
	var width := _lane_x(5) - _lane_x(0) + LANE
	var height := float(obstacle[1])
	if height > 0.0:
		_box(Vector3(width, height, 0.12), Vector3(0.0, height * 0.5, 0.0))
	else:
		# LA VIGA, a la altura de la frente del más bajo: todos se la llevan puesta (dos parantes la sostienen).
		var beam_y := 1.3
		_box(Vector3(width + 0.4, 0.18, 0.18), Vector3(0.0, beam_y, 0.0))
		for side: float in [-1.0, 1.0]:
			_box(Vector3(0.15, beam_y, 0.15), Vector3(side * (width * 0.5 + 0.2), beam_y * 0.5, 0.0))
	_wait(SETTLE_S)
	_step(_each(func(i: int, a: CharacterActions) -> void:
			# FRENAN APRETANDO PARA ATRÁS: soltando, sueltan a unos 10 m del final (lo que tardan en frenar solos) y pasan la
			# valla sin apretar nada.
			a.go_to(_goal(i, END_Z), _row.sprint, true)
			if height > 0.0:
				a.jump_over(_goal(i, 0.0))),
		_all(func(a: CharacterActions) -> bool: return not a.moving()))


## ── CAER DE ALTO: corren por una plataforma y siguen de largo; aterrizan (o se caen) y se levantan.
func _build_drop() -> void:
	var height: float = LocomotionLabArchetype.DROP_HEIGHTS[_row.option_j]
	var width := _lane_x(5) - _lane_x(0) + LANE
	var edge := -2.0
	_box(Vector3(width + 0.6, height, edge - (START_Z - 1.5)), Vector3(0.0, height * 0.5, (edge + START_Z - 1.5) * 0.5))
	for i in PEOPLE.size():
		_person(PEOPLE[i], Vector3(_lane_x(i), height, START_Z))
	_wait(SETTLE_S)
	_step(_each(func(i: int, a: CharacterActions) -> void: a.go_to(_goal(i, END_Z), _row.sprint, true)),
		_all(func(a: CharacterActions) -> bool: return not a.moving()))


## ── LLEVAR Y TIRAR: levantan el cubo que tienen adelante, lo llevan hasta el medio y lo tiran.
func _build_carry() -> void:
	_lane_people(START_Z)
	for i in PEOPLE.size():
		_cube(i, Vector3(_lane_x(i), SupplyLook.H, START_Z + 1.2))
	var charge: float = LocomotionLabArchetype.THROW_CHARGES[_row.option_j]
	_wait(SETTLE_S)
	_step(_each(func(i: int, a: CharacterActions) -> void: a.carry(_cubes[i])),
		_all(func(a: CharacterActions) -> bool: return a.carrying()))
	_step(_each(func(i: int, a: CharacterActions) -> void: a.go_to(_goal(i, 0.0), _row.sprint)),
		_all(func(a: CharacterActions) -> bool: return not a.moving()))
	_step(_each(func(_i: int, a: CharacterActions) -> void: a.throw(charge, 0.25)),
		_all(func(a: CharacterActions) -> bool: return a.empty_handed()))


## ── ATAJAR: a cada uno le tiran un cubo desde 8 m; lo siguen con la mirada y lo atajan (o se lo comen).
func _build_catch() -> void:
	var at_z := 4.0
	_lane_people(at_z, -1.0)
	var speed: float = LocomotionLabArchetype.CATCH_SPEEDS[_row.option_j]
	var from: int = _row.option_u
	_wait(SETTLE_S)
	_step(func() -> void:
		var gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
		for i in _people.size():
			var bi := _people[i]
			var chest := bi.get_interaction_origin()
			var start := to_global(Vector3(_lane_x(i) + (2.5 if from == 2 else 0.0), 1.2 if from != 1 else 2.6, at_z - 8.0))
			var cube := _cube(i, to_local(start))
			# SIN EL FRENO DEL AIRE, así llega adonde se apuntó (con el de siempre caía un metro corto).
			cube.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
			cube.linear_damp = 0.0
			var flight := Vector2(chest.x - start.x, chest.z - start.z)
			var t := flight.length() / speed
			var dir := flight.normalized() * speed
			cube.linear_velocity = Vector3(dir.x, (chest.y - start.y + 0.5 * gravity * t * t) / t, dir.y)
			CharacterActions.of(bi).catch(cube),
		_all(func(a: CharacterActions) -> bool: return a.carrying()), 1.0)


## ── ESQUIVAR BARRILES: cada uno en su carril, en zigzag a un costado y al otro de cada barril, por un camino fijo (no
## los ve: si no le da el giro, se lo lleva puesto).
const SLALOM_LANE := 4.0
const SLALOM_SIDE := 1.8
const SLALOM_FIRST := 5.0
const SLALOM_START := -11.0
const SLALOM_END := 11.0
const BARREL_R := 0.45
const BARREL_H := 1.0
const BARREL_COLOR := Color(0.62, 0.42, 0.3)


func _build_slalom() -> void:
	var gap: float = LocomotionLabArchetype.SLALOM_STEPS[_row.option_j][1]
	var barrels: Array[float] = []
	var z := SLALOM_START + SLALOM_FIRST
	while z < SLALOM_END - 2.0:
		barrels.append(z)
		z += gap
	var paths: Array[PackedVector3Array] = []
	for i in PEOPLE.size():
		var x := _lane_x(i, PEOPLE.size(), SLALOM_LANE)
		_person(PEOPLE[i], Vector3(x, 0.0, SLALOM_START))
		var path := PackedVector3Array([to_global(Vector3(x, 0.0, SLALOM_START))])
		for b in barrels.size():
			_barrel(Vector3(x, 0.0, barrels[b]))
			path.append(to_global(Vector3(x + (SLALOM_SIDE if b % 2 == 0 else -SLALOM_SIDE), 0.0, barrels[b])))
		path.append(to_global(Vector3(x, 0.0, SLALOM_END)))
		paths.append(path)
	_wait(SETTLE_S)
	_step(_each(func(i: int, a: CharacterActions) -> void: a.follow_path(paths[i], _row.sprint, true)),
		_all(func(a: CharacterActions) -> bool: return not a.moving()))


func _barrel(at_local: Vector3) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = at_local + Vector3.UP * BARREL_H * 0.5
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = BARREL_R
	cylinder.height = BARREL_H
	shape.shape = cylinder
	body.add_child(shape)
	Clay.cylinder(body, BARREL_R, BARREL_H, Vector3.ZERO, BARREL_COLOR)
