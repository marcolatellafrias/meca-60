class_name TestBeast
extends Node3D

## EL BICHO DE PRUEBA: un monstruo grande que no ataca, para probar cómo se siente pegarle y dispararle. Un cuerpo
## redondo sobre cuatro patas, y LAS PARTES POR SEMILLA: de uno a tres tentáculos, uno o dos ojos, cuernos o no, y su
## color y tamaño. Cada parte se rompe aparte (BeastPart); si se rompe el cuerpo, el bicho queda tirado.
##
## EL EQUILIBRIO, como el de la meca (ver Mech): un resorte de dos ejes que empujan los golpes; si pasa de 1, el bicho
## SE CAE para ese lado, queda en el suelo y se levanta solo. Gira despacio para mirar a la meca.
##
## Es la base de los jefes por venir: pocos arquetipos hechos a mano, con las partes por semilla y afijos encima.

const HEIGHT := 9.0
const RADIUS := 7.0
const SPRING := 3.2
const DAMPING := 1.8
const TURN_SPEED := 0.4
const FALL_TIME := 1.1
const DOWN_TIME := 4.0
const RISE_TIME := 2.2
const FALLEN_ANGLE := deg_to_rad(75.0)

enum State { STANDING, FALLING, DOWN, RISING, DEAD }

## A quién mira (la meca), si hay.
var target: Node3D = null
var stability := Vector2.ZERO
var state := State.STANDING
var parts: Array[BeastPart] = []

var _speed := Vector2.ZERO
var _body: Node3D = null
var _fall_direction := Vector2.ZERO
var _fall_from := 0.0
var _clock := 0.0
var _tentacles: Array[Node3D] = []
var _time := 0.0
var _size := 1.0


## Arma el bicho de la semilla.
func build(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_size = rng.randf_range(0.9, 1.2)
	var skin := Color.from_hsv(rng.randf(), rng.randf_range(0.35, 0.6), rng.randf_range(0.45, 0.7))
	_body = Node3D.new()
	_body.name = "Cuerpo"
	_body.scale = Vector3.ONE * _size
	add_child(_body)
	# Las patas: no se rompen, pero chocan.
	var legs := StaticBody3D.new()
	legs.name = "Patas"
	_body.add_child(legs)
	for corner in 4:
		var at := Vector3(-3.5 if corner % 2 == 0 else 3.5, HEIGHT * 0.35, -3.0 if corner < 2 else 3.0)
		Clay.solid(legs, Vector3(1.8, HEIGHT * 0.7, 1.8), at, skin.darkened(0.35))
	# El cuerpo.
	var core := _part("cuerpo", 400.0, Vector3(0, HEIGHT, 0), HEIGHT * 0.75)
	var belly := Clay.sphere(core, 1.0, Vector3.ZERO, skin)
	belly.scale = Vector3(6.5, 4.5, 7.0)
	Clay.shape_box(core, Vector3(12.0, 8.0, 13.0), Vector3.ZERO)
	core.broken.connect(func(_part_broken: BeastPart) -> void: _die())
	# Los ojos, al frente (−Z).
	var eyes := rng.randi_range(1, 2)
	for i in eyes:
		var x := 0.0 if eyes == 1 else (-1.8 if i == 0 else 1.8)
		var eye := _part("ojo", 40.0, Vector3(x, HEIGHT + 1.5, -6.4), 2.2)
		Clay.sphere(eye, 1.3, Vector3.ZERO, Color(0.95, 0.95, 0.9))
		Clay.sphere(eye, 0.6, Vector3(0, 0, -1.0), Clay.DARK)
		Clay.shape_box(eye, Vector3(2.6, 2.6, 2.6), Vector3.ZERO)
	# Los cuernos.
	if rng.randf() < 0.6:
		for side: float in [-1.0, 1.0]:
			var horn := _part("cuerno", 50.0, Vector3(side * 3.0, HEIGHT + 4.0, -2.0), 3.5)
			var spike := Clay.cylinder(horn, 0.7, 4.0, Vector3(0, 1.5, 0), Color(0.9, 0.85, 0.7))
			spike.rotation_degrees.z = -side * 25.0
			(spike.mesh as CylinderMesh).top_radius = 0.1
			Clay.shape_box(horn, Vector3(1.6, 4.0, 1.6), Vector3(0, 1.5, 0))
	# Los tentáculos, al frente y a los costados.
	var tentacles := rng.randi_range(1, 3)
	var spots := [Vector3(-4.5, HEIGHT - 1.0, -4.5), Vector3(4.5, HEIGHT - 1.0, -4.5), Vector3(0, HEIGHT - 2.5, -6.0)]
	for i in tentacles:
		var tentacle := _part("tentáculo", 60.0, spots[i], 2.0)
		var chain := Node3D.new()
		chain.name = "Cadena"
		tentacle.add_child(chain)
		var link := chain
		for segment in 6:
			var piece := Node3D.new()
			piece.position = Vector3(0, -0.4, -1.4) if segment > 0 else Vector3.ZERO
			link.add_child(piece)
			Clay.sphere(piece, 1.0 - segment * 0.12, Vector3.ZERO, skin.lightened(0.15))
			link = piece
		Clay.shape_box(tentacle, Vector3(2.2, 3.0, 8.0), Vector3(0, -1.2, -3.8))
		_tentacles.append(chain)
	for part in parts:
		part.setup(part.part_name, part.health, self, part.get_meta("label_height", 2.0))


func _part(part_name: String, health: float, at: Vector3, label_height: float) -> BeastPart:
	var part := BeastPart.new()
	part.name = part_name.capitalize()
	part.part_name = part_name
	part.health = health
	part.position = at
	part.set_meta("label_height", label_height)
	_body.add_child(part)
	parts.append(part)
	return part


## UN EMPUJÓN al equilibrio, desde un golpe: `direction` en el mundo.
func push(direction: Vector3, amount: float) -> void:
	if state != State.STANDING:
		return
	var local := global_basis.inverse() * direction
	_speed += Vector2(local.x, -local.z).limit_length(1.0) * amount


## Si `at` está lejos del bicho (para la meca y la arena).
func clear_of(at: Vector3, radius: float) -> bool:
	var flat := Vector2(at.x - global_position.x, at.z - global_position.z)
	return flat.length() > RADIUS * _size + radius


func _physics_process(delta: float) -> void:
	_time += delta
	match state:
		State.STANDING:
			_speed += (-stability * SPRING - _speed * DAMPING) * delta
			stability += _speed * delta
			if stability.length() > 1.0:
				_start_fall()
			elif target != null and is_instance_valid(target):
				var to := target.global_position - global_position
				var wanted := atan2(-to.x, -to.z)
				rotation.y = rotate_toward(rotation.y, wanted, TURN_SPEED * delta)
		State.FALLING, State.DOWN, State.RISING:
			_clock += delta
			if state == State.FALLING and _clock >= FALL_TIME:
				state = State.DOWN
				_clock = 0.0
			elif state == State.DOWN and _clock >= DOWN_TIME:
				state = State.RISING
				_clock = 0.0
			elif state == State.RISING and _clock >= RISE_TIME:
				state = State.STANDING
				stability = Vector2.ZERO
				_speed = Vector2.ZERO
		State.DEAD:
			_clock += delta
	_pose()
	# Los tentáculos se mecen.
	for i in _tentacles.size():
		var link := _tentacles[i].get_child(0) as Node3D
		var depth := 0
		while link != null:
			link.rotation = Vector3(sin(_time * 1.3 + i + depth * 0.6) * 0.18, sin(_time * 0.9 + i * 2.0 + depth) * 0.22, 0.0)
			depth += 1
			# Cada eslabón tiene su esfera y, después, el que sigue.
			link = link.get_child(1) as Node3D if link.get_child_count() > 1 else null


func _start_fall() -> void:
	state = State.FALLING
	_clock = 0.0
	_fall_direction = stability.normalized()
	_fall_from = stability.length() * deg_to_rad(10.0)


func _die() -> void:
	if state == State.DEAD:
		return
	if state == State.STANDING:
		_fall_direction = stability.normalized() if stability.length() > 0.01 else Vector2(0, -1)
		_fall_from = stability.length() * deg_to_rad(10.0)
	state = State.DEAD
	_clock = 0.0


## El cuerpo inclinado: con el equilibrio parado, y de costado al caerse.
func _pose() -> void:
	var lean := stability * deg_to_rad(10.0)
	var drop := 0.0
	match state:
		State.FALLING:
			var share := ease(clampf(_clock / FALL_TIME, 0.0, 1.0), 2.4)
			lean = _fall_direction * lerpf(_fall_from, FALLEN_ANGLE, share)
			drop = share * 2.5
		State.DOWN:
			lean = _fall_direction * FALLEN_ANGLE
			drop = 2.5
		State.RISING:
			var share := ease(clampf(_clock / RISE_TIME, 0.0, 1.0), -2.0)
			lean = _fall_direction * lerpf(FALLEN_ANGLE, 0.0, share)
			drop = (1.0 - share) * 2.5
		State.DEAD:
			var share := ease(clampf(_clock / FALL_TIME, 0.0, 1.0), 2.4)
			lean = _fall_direction * lerpf(_fall_from, FALLEN_ANGLE, share)
			drop = share * 2.5
	var tilt := Basis()
	if lean.length() > 0.0001:
		var toward := Vector3(lean.x, 0.0, -lean.y).normalized()
		tilt = Basis(Vector3.UP.cross(toward).normalized(), lean.length())
	_body.transform = Transform3D(tilt * Basis.from_scale(Vector3.ONE * _size), Vector3(0, -drop, 0))
