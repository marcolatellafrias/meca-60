class_name TestBall
extends RigidBody3D

## UNA BOLA DE PRUEBA para empujar cosas y ver cómo reaccionan: sale de la cámara, hacia donde se mira. Choca de verdad
## (también con las piezas de un muñeco caído, capa 2) y desaparece sola. Si toca algo con `take_hit` (una meca de
## pelea), le pega como una bala, con su empuje.
##
## UNA SOLA BOLA, TRES FUERZAS (11/11/2026, el usuario: «un solo tamaño de bola y varias cosas de distintas fuerzas»;
## «que sea una sola tecla pasando por las fuerzas… pone 3»): siempre del mismo tamaño y a la misma velocidad; lo que
## cambia es su EMPUJE (masa × velocidad, en N·s), y la masa sale de él. LAS TRES LAS DICE CADA FILA para lo que tiene
## (el usuario: «que sean acordes al threshold de la nave»; después, «por fila»; ver SeededArchetype.ball_pushes): una
## lo mueve, otra lo deja a punto de caerse (trastabilla, se tambalea) y otra lo tira, con sus umbrales de ahora —si se
## tocan las perillas de su panel (F1), las fuerzas las siguen—. Lo elegido (cuál de las tres) es uno solo para todas
## las parcelas: J tira, K pasa a la siguiente.

const RADIUS := 0.6
const SPEED := 25.0
const LIFETIME := 12.0
const NAMES := ["lo mueve", "a punto de caer", "lo tira"]

## Lo elegido, para todas las parcelas.
static var level := 1

var _age := 0.0
var _struck := {}


func _init() -> void:
	name = "Bola"
	continuous_cd = true
	# Sólo la capa del mundo y los cuerpos: los huesos de las personas de character-parametric chocan aunque estén
	# paradas (capa 2), y un golpe ahí no llega a la cápsula, que es la que mide el golpe (el chico casi no se movía).
	collision_mask = 1
	# NO CAE: va derecho y pega donde se apunta (con caída, de 25 m le pegaba metro y medio más abajo, y las fuerzas de
	# cada fila, que cuentan dónde pega, no se cumplían).
	gravity_scale = 0.0
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


## La tira desde la cámara activa, hacia donde mira, con `push` de empuje (N·s).
static func throw_from_camera(scene: Node, push: float) -> TestBall:
	var camera := scene.get_viewport().get_camera_3d()
	if camera == null or push <= 0.0 or is_inf(push):
		return null
	var ball := TestBall.new()
	ball.mass = push / SPEED
	scene.add_child(ball)
	var forward := -camera.global_basis.z
	ball.global_position = camera.global_position + forward * (RADIUS + 1.0)
	ball.linear_velocity = forward * SPEED
	return ball


## EL EMPUJE QUE HACE FALTA PARA DARLE `delta_v` (m/s) a algo de `mass` kg, con una bola a `SPEED` que se queda pegada:
## Δv = m_bola·v / (masa + m_bola), y m_bola = empuje / v. Lo más que puede darle es casi su propia velocidad: más que
## eso, se queda en lo más (una bola de diez veces la masa del blanco).
static func push_for(mass: float, delta_v: float) -> float:
	var reachable := minf(delta_v, SPEED * 10.0 / 11.0)
	return mass * reachable * SPEED / (SPEED - reachable)


## Las teclas de la bola, con las fuerzas de `target` (el arquetipo de la parcela: ver SeededArchetype.ball_pushes).
static func parcel_options(target: SeededArchetype) -> Array[Dictionary]:
	return [
		{"key": KEY_J, "label": func() -> String: return "tirar una bola (%s: %s N·s)" % [NAMES[level],
				String.num_int64(roundi(TestBall.push_at(target, level)))],
			"apply": func(parcel: SandboxParcel) -> void: TestBall.throw_from_camera(parcel, TestBall.push_at(target, level))},
		{"key": KEY_K, "label": func() -> String: return "otra fuerza (%d de %d)" % [level + 1, NAMES.size()],
			"apply": func(_parcel: SandboxParcel) -> void: level = (level + 1) % NAMES.size()},
	]


## La fuerza `force` (0 a 2) de `target`.
static func push_at(target: SeededArchetype, force: int) -> float:
	var pushes := target.ball_pushes()
	return float(pushes[clampi(force, 0, pushes.size() - 1)]) if not pushes.is_empty() else 0.0


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
