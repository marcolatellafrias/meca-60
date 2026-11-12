class_name TestBall
extends RigidBody3D

## UNA BOLA DE PRUEBA para empujar cosas y ver cómo reaccionan: sale de la cámara, hacia donde se mira. Choca de verdad
## (también con las piezas de un muñeco caído, capa 2) y desaparece sola. Si toca algo con `take_hit` (una meca de
## pelea), le pega como una bala, con su empuje.
##
## UNA SOLA BOLA, TRES FUERZAS (11/11/2026, el usuario: «un solo tamaño de bola y varias cosas de distintas fuerzas»;
## después: «que sea una sola tecla pasando por las fuerzas… pone 3»): siempre del mismo tamaño y a la misma velocidad;
## lo que cambia es su EMPUJE (masa × velocidad, en N·s), y la masa sale de él. LAS TRES SALEN DE LOS UMBRALES DE LA MECA
## DE EQUILIBRIO, los de ahora (el usuario: «que sean acordes al threshold de la nave»; ver MechDummy.push_for_lean): la
## que la mueve llega a una parte de donde da un paso (`step_at`); la que la hace trastabillar, entre el paso y la caída
## (`fall_at`); la que la tira, más allá de la caída. Si se tocan las perillas en el panel (F1), las fuerzas las siguen.
## A una persona, cualquiera de las tres la voltea. Lo elegido es uno solo para todas las parcelas (ver
## `parcel_options`): J tira, K pasa a la fuerza siguiente.

const RADIUS := 0.6
const SPEED := 25.0
const LIFETIME := 12.0
const NAMES := ["la mueve", "trastabilla", "la tira"]
## Dónde apunta cada una: entre 0 y 1 es una parte del umbral del paso; entre 1 y 2, de ahí al umbral de la caída; más
## de 2, pasada la caída.
const AIMS := [0.7, 1.5, 2.25]

## Lo elegido, para todas las parcelas.
static var level := 1

var _age := 0.0
var _struck := {}


func _init() -> void:
	name = "Bola"
	continuous_cd = true
	collision_mask = 1 | 2
	# Cae poco, como las balas del cañón: así llega derecha.
	gravity_scale = 0.25
	contact_monitor = true
	max_contacts_reported = 4
	var material := PhysicsMaterial.new()
	material.bounce = 0.1
	material.friction = 0.6
	physics_material_override = material
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = RADIUS
	shape.shape = sphere
	add_child(shape)
	Clay.sphere(self, RADIUS, Vector3.ZERO, Clay.YELLOW.darkened(0.2))
	body_entered.connect(_on_body)


## El empuje de la fuerza `force` (N·s), con los umbrales de ahora.
static func push_of(force: int) -> float:
	return MechDummy.push_for_lean(lean_of(force), SPEED)


## La inclinación a la que apunta la fuerza `force` (ver `AIMS`).
static func lean_of(force: int) -> float:
	var settings := MechBalanceSettings.current
	var aim := float(AIMS[clampi(force, 0, AIMS.size() - 1)])
	if aim <= 1.0:
		return settings.step_at * aim
	if aim <= 2.0:
		return lerpf(settings.step_at, settings.fall_at, aim - 1.0)
	# Pasada la caída, más lo que la salvaría un paso, si da pasos.
	return settings.fall_at * (aim - 1.0) + (settings.step_catch if settings.steps else 0.0)


## La tira desde la cámara activa, hacia donde mira, con el empuje del escalón `force`.
static func throw_from_camera(scene: Node, force: int) -> TestBall:
	var camera := scene.get_viewport().get_camera_3d()
	if camera == null:
		return null
	var ball := TestBall.new()
	ball.mass = push_of(force) / SPEED
	scene.add_child(ball)
	var forward := -camera.global_basis.z
	ball.global_position = camera.global_position + forward * (RADIUS + 1.0)
	ball.linear_velocity = forward * SPEED
	return ball


## Las teclas de la bola, para cualquier parcela que las quiera.
static func parcel_options() -> Array[Dictionary]:
	return [
		{"key": KEY_J, "label": func() -> String: return "tirar una bola (%s: inclinación %d %%, %s N·s)" % [
				NAMES[level], roundi(lean_of(level) * 100.0), String.num_int64(roundi(push_of(level)))],
			"apply": func(parcel: SandboxParcel) -> void: TestBall.throw_from_camera(parcel, level)},
		{"key": KEY_K, "label": func() -> String: return "otra fuerza (%d de %d)" % [level + 1, AIMS.size()],
			"apply": func(_parcel: SandboxParcel) -> void: level = (level + 1) % AIMS.size()},
	]


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > LIFETIME:
		queue_free()


## A una meca de pelea le pega como un puño de su mismo empuje (ver MechArm.HIT_PUSH, por m/s de un puño de 2,5 t).
func _on_body(body: Node) -> void:
	var target := MechArm.hittable(body)
	if target == null or _struck.has(target.get_instance_id()):
		return
	_struck[target.get_instance_id()] = true
	var speed := linear_velocity.length()
	var push := linear_velocity.length() * mass / 2500.0 * MechArm.HIT_PUSH
	target.take_hit(speed, linear_velocity.normalized(), push)
