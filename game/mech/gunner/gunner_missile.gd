class_name GunnerMissile
extends Node3D

## UN MISIL (ver GunnerWeapons; el usuario, 22/11/2026: «como una habilidad de la Yumi… guiarlo un poco al principio… termina
## detonando donde está»). Sale de su tubo con su estela. Durante `guide` segundos se tuerce hacia la mira de quien lo lanzó
## (`steer`), plano y a lo más `turn` °/s; después sigue derecho. AL TOCAR ALGO O AL RECORRER `reach` METROS EXPLOTA en un
## círculo de `radius`: entero en el medio y la mitad en el borde. Así nunca se queda dando vueltas ni sale de lo que se ve.
## EN RED cada máquina tiene el suyo (ver MechGuns); el golpe lo aplica sólo el host.

const GROUP := "misiles_guiados"
const START := 25.0
const ACCEL := 140.0
const LIFE := 5.0
## La parte de su velocidad tope a la que va cuando tiene que doblar 90° o más.
const TURNING_PACE := 0.3
## Lo ancho que toca volando, en el piso (m).
const HIT_WIDTH := 0.4
## El golpe de la explosión (kg·m/s) en el medio (ver EnergyBolt.lands).
const IMPULSE := 220000.0
const MASK := 1 | PhysicsLayers.FIXED
const BODY := Color(0.62, 0.6, 0.42)

## Adónde ir (mundo): una función sin argumentos que lo devuelve (Vector3.INF, sin mira), o vacía.
var steer := Callable()
## La máquina que lo lanzó, su velocidad tope (m/s) y lo que dobla (°/s). Los manda quien dispara (ver MechGuns).
var launcher := 0
var top := 32.0
var turn := 150.0
var strength := 1.0
## QUÉ MISIL ES (SupplyKinds): el REBOTADOR salta y explota otra vez, el de RACIMO suelta cuatro chicos y la MINA se queda en el
## piso hasta que un blanco le pasa cerca.
var kind: int = SupplyKinds.Kind.MISSILES
const HOP_REACH := 5.5
const HOP_RADIUS := 0.75
const HOP_POWER := 0.6
const BOMBLETS := 4
const BOMBLET_REACH := 3.6
const BOMBLET_RADIUS := 0.55
const BOMBLET_POWER := 0.4
const MINE_LIFE := 14.0
const MINE_TRIGGER := 1.6
const MINE_BLINK := 3.0
var _armed := false
var _armed_for := 0.0
var _light: MeshInstance3D = null
## Hasta dónde vuela (m), el radio de la explosión (m) y cuánto se lo puede guiar (s).
var reach := MechSkills.RANGE
var radius := 3.0
var guide := 0.45
var _flown := 0.0
var skip: Array[RID] = []
var _speed := START
var _age := 0.0
## Cuántos se dibujaron en esta máquina (para los tests de red).
static var made := 0
var _trail: GPUParticles3D = null


func _ready() -> void:
	made += 1
	add_to_group(GROUP)
	_speed = minf(START, top)
	Clay.cylinder(self, 0.13, 1.1, Vector3.ZERO, BODY, Vector3(90.0, 0.0, 0.0))
	Clay.sphere(self, 0.13, Vector3(0.0, 0.0, -0.55), Color(0.85, 0.35, 0.25))
	_trail = ParticleSystems.thruster_smoke(ParticleMeshes.Kind.SPHERE, 0.5)
	_trail.position = Vector3(0.0, 0.0, 0.65)
	add_child(_trail)
	_trail.emitting = true


func _physics_process(delta: float) -> void:
	if _armed:
		_mine_step(delta)
		return
	_age += delta
	var goal: Vector3 = steer.call() if steer.is_valid() and _age <= guide else Vector3.INF
	var angle := 0.0
	if goal.is_finite():
		goal.y = global_position.y
		var ahead := -global_basis.z
		var wanted := (goal - global_position).normalized()
		angle = ahead.angle_to(wanted)
		if angle > 0.001:
			var axis := ahead.cross(wanted).normalized()
			if axis.length() > 0.5:
				global_basis = Basis(axis, minf(angle, deg_to_rad(turn) * delta)) * global_basis.orthonormalized()
	# FRENA PARA DOBLAR: a toda velocidad, un blanco cerca y al costado le queda adentro de la curva y lo orbita sin tocarlo.
	var pace := lerpf(1.0, TURNING_PACE, clampf(angle / (PI * 0.5), 0.0, 1.0))
	_speed = move_toward(_speed, top * pace, ACCEL * delta)
	var from := global_position
	var to := from - global_basis.z * _speed * delta
	# LOS BLANCOS SE TOCAN EN EL PISO (ver HitTarget): vaya a la altura que vaya, explota al llegar.
	var target := HitTarget.first_on_line(get_tree(), from, to, HIT_WIDTH)
	if target != null:
		_explode(target.surface(from))
		return
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, MASK, skip))
	if not hit.is_empty():
		if kind == SupplyKinds.Kind.MINE:
			_arm(from)
		else:
			_explode(hit["position"])
		return
	global_position = to
	_flown += from.distance_to(to)
	if _flown >= reach or _age > LIFE:
		if kind == SupplyKinds.Kind.MINE:
			_arm(global_position)
		else:
			_explode(global_position)


## LA MINA SE APOYA EN EL PISO y espera, titilando.
func _arm(at: Vector3) -> void:
	_armed = true
	remove_from_group(GROUP)
	var query := PhysicsRayQueryParameters3D.create(at, at + Vector3.DOWN * 12.0, PhysicsLayers.FIXED, skip)
	var ground := get_world_3d().direct_space_state.intersect_ray(query)
	var floor_at: Vector3 = ground["position"] if not ground.is_empty() else at
	for child in get_children():
		if child is MeshInstance3D:
			(child as Node3D).visible = false
	_leave_trail()
	global_transform = Transform3D(Basis(), floor_at + Vector3.UP * 0.12)
	Clay.cylinder(self, 0.42, 0.2, Vector3.ZERO, Color(0.32, 0.24, 0.34))
	_light = Clay.cylinder(self, 0.14, 0.06, Vector3.UP * 0.12, SupplyKinds.tag_color(SupplyKinds.Kind.MINE))
	_light.material_override = EnergyBolt.shine(SupplyKinds.tag_color(SupplyKinds.Kind.MINE))


func _mine_step(delta: float) -> void:
	_armed_for += delta
	_light.visible = fmod(_armed_for * MINE_BLINK, 1.0) < 0.5
	if _armed_for >= MINE_LIFE or not HitTarget.in_circle(get_tree(), global_position, MINE_TRIGGER).is_empty():
		_explode(global_position)


## LO QUE SALE DE LA EXPLOSIÓN: el salto del rebotador o los chicos del racimo.
func _children(at: Vector3) -> void:
	var ahead := -global_basis.z
	ahead.y = 0.0
	ahead = ahead.normalized() if ahead.length() > 0.01 else Vector3.FORWARD
	if kind == SupplyKinds.Kind.BOUNCER:
		_child(at, ahead, HOP_REACH, HOP_RADIUS, HOP_POWER)
	elif kind == SupplyKinds.Kind.CLUSTER:
		for index in BOMBLETS:
			_child(at, ahead.rotated(Vector3.UP, TAU * (index + 0.5) / BOMBLETS), BOMBLET_REACH, BOMBLET_RADIUS, BOMBLET_POWER)


func _child(at: Vector3, way: Vector3, long: float, size: float, power: float) -> void:
	var made := GunnerMissile.new()
	made.skip = skip
	made.launcher = 0
	made.top = top
	made.turn = 0.0
	made.guide = 0.0
	made.reach = long
	made.radius = radius * size
	made.strength = strength * power
	made.scale = Vector3.ONE * 0.7
	get_tree().current_scene.add_child(made)
	made.global_transform = Transform3D(Basis.looking_at(way, Vector3.UP).scaled(Vector3.ONE * 0.7), at + way * 0.3)


## La estela se queda donde estaba y se apaga sola.
func _leave_trail() -> void:
	if not is_instance_valid(_trail) or _trail.get_parent() != self:
		return
	var keep := _trail.global_transform
	remove_child(_trail)
	get_tree().current_scene.add_child(_trail)
	_trail.global_transform = keep
	_trail.emitting = false
	get_tree().create_timer(_trail.lifetime + 0.5).timeout.connect(_trail.queue_free)


## EXPLOTA en `at`: lo que se ve, y el golpe a lo suelto del radio.
func _explode(at: Vector3) -> void:
	GunnerFx.blast(at, 1.6)
	MechSounds.loose(MechSounds.MISSILE_BLAST, at, get_tree(), randf_range(0.9, 1.1))
	var query := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = radius
	query.shape = ball
	query.transform = Transform3D(Basis(), at)
	query.collision_mask = 1
	query.exclude = skip
	var struck := {}
	var hits: Array = [] if ProjectileField.is_client(self) else get_world_3d().direct_space_state.intersect_shape(query, 16)
	# LOS BLANCOS, POR UN CÍRCULO EN EL PISO: entero en el medio y la mitad en el borde.
	for target in HitTarget.in_circle(get_tree(), at, radius):
		var toward := target.center() - at
		toward.y = 0.0
		var edge := maxf(toward.length() - target.flat_radius(), 0.0)
		var part := 1.0 - 0.5 * clampf(edge / radius, 0.0, 1.0)
		var way := toward.normalized() if toward.length() > 0.01 else -global_basis.z
		target.strike("misil", part * strength, IMPULSE * part * strength, at, way)
	for found in hits:
		var body := EnergyBolt.struck(found["collider"])
		if body == null or struck.has(body.get_instance_id()) or HitTarget.of_body(body) != null:
			continue
		struck[body.get_instance_id()] = true
		var away := body.global_position - at
		var share := 1.0 - 0.5 * clampf(away.length() / radius, 0.0, 1.0)
		EnergyBolt.lands(body, away.normalized() * IMPULSE * share * strength, at, "misil")
	_leave_trail()
	_children(at)
	queue_free()
