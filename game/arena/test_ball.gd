class_name TestBall
extends RigidBody3D

## UNA BOLA DE PRUEBA para empujar cosas y ver cómo reaccionan: sale de la cámara, hacia donde se mira. Choca de verdad
## (también con las piezas de un muñeco caído, capa 2) y desaparece sola. Si toca algo con `take_hit` (una meca de
## pelea), le pega como una bala, con su empuje.
##
## UNA SOLA BOLA, VARIAS FUERZAS (11/11/2026, el usuario: «un solo tamaño de bola y varias cosas de distintas fuerzas»):
## siempre del mismo tamaño y a la misma velocidad; lo que cambia es su EMPUJE (masa × velocidad, en N·s), en escalones
## que van de mover a una persona a voltear a la meca. La masa sale del empuje. Lo elegido es uno solo para todas las
## parcelas (ver `parcel_options`): J tira, K y L bajan y suben la fuerza.

const RADIUS := 0.6
const SPEED := 25.0
const LIFETIME := 12.0
## Los empujes, en N·s. Como referencia, lo que hace falta para tirarlos de frente: una persona de 100 kg, unos 300; la
## meca de equilibrio (50 t), unos 140 000.
const PUSHES := [100.0, 250.0, 600.0, 1500.0, 4000.0, 10000.0, 25000.0, 50000.0, 90000.0, 140000.0, 200000.0, 300000.0]

## Lo elegido, para todas las parcelas.
static var level := 5

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


## El empuje del escalón `force` (N·s).
static func push_of(force: int) -> float:
	return float(PUSHES[clampi(force, 0, PUSHES.size() - 1)])


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
		{"key": KEY_J, "label": func() -> String: return "tirar una bola (fuerza %d de %d: %s N·s)" % [level + 1,
				PUSHES.size(), String.num_int64(roundi(push_of(level)))],
			"apply": func(parcel: SandboxParcel) -> void: TestBall.throw_from_camera(parcel, level)},
		{"key": KEY_K, "label": "menos fuerza",
			"apply": func(_parcel: SandboxParcel) -> void: level = maxi(level - 1, 0)},
		{"key": KEY_L, "label": "más fuerza",
			"apply": func(_parcel: SandboxParcel) -> void: level = mini(level + 1, PUSHES.size() - 1)},
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
