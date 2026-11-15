class_name BrawlerBody
extends RefCounted

## EL DIBUJO DEL LUCHADOR DE ORUGAS (ver Brawler): la maqueta elegida (HumanoidMaquettes, «Luchador de orugas»), armada
## en piezas que se mueven. Arcilla de cajas: los miembros, cuadrados.
##   · LAS ORUGAS (`hull`): dos orugas con sus ruedas, el chasis y el aro donde gira la cintura. Van con el cuerpo.
##   · LO DE ARRIBA (`upper`): la cintura, el pecho ancho, los brazos en guardia, la cabeza hundida con su visor y las
##     dos chimeneas. Gira aparte, sobre el aro.
##   · EL HORNO (el usuario: «que las furnace no sean dos cosas separadas, sino una sola al medio, abajo, y que se note
##     que es como un horno… una puerta que se abra… hacia arriba, porque si se abre hacia un costado la puerta va a
##     tapar el punto débil»): un solo horno al medio del pecho, abajo, con la bisagra arriba (`door`).
##   · LA IRA (`fury`, de 0 a 1): el color pasa al de la ira, el visor se pone rojo, el horno brilla más y las chimeneas
##     echan humo negro (el usuario: «los tubos de atrás son los perfectos para que tiren humo cuando está enojado»).

const COLOR := Color(0.62, 0.2, 0.18)
const RAGE_COLOR := Color(0.2, 0.2, 0.22)
const EYE := Color(0.45, 0.95, 1.0)
const RAGE_EYE := Color(1.0, 0.12, 0.08)
const FIRE := Color(1.0, 0.45, 0.1)

## LAS MEDIDAS (m), las de la maqueta. El alto de la cintura sobre el piso, el chasis, la oruga, el pecho, los brazos.
const HIP := 9.0
const WAIST := Vector3(12, 5, 10)
const CHEST := Vector3(22, 13, 13)
const HUNCH := 12.0
const SHOULDER := Vector3(7, 7, 7)
const UPPER_ARM := 8.0
const FOREARM := 9.0
const REACH := 0.35
const FIST := 4.8
const TRACK := Vector3(5.0, 5.5, 24.0)
## El horno: la boca (ancho y alto, m) y lo hondo.
const FURNACE := Vector2(9.0, 5.0)

## Las piezas que se mueven.
var hull: Node3D = null
var upper: Node3D = null
var door: Node3D = null
var smoke: Array[GPUParticles3D] = []

var _paint := StandardMaterial3D.new()
var _trim := StandardMaterial3D.new()
var _eye := StandardMaterial3D.new()
var _fire := StandardMaterial3D.new()
var _shown_fury := -1.0


## LO ARMA colgado de `owner` (el Luchador): las orugas, hijas suyas; lo de arriba, aparte (gira solo).
func build(owner: Node3D) -> void:
	for made in [_paint, _trim]:
		made.roughness = 0.85
	_eye.emission_enabled = true
	_fire.emission_enabled = true
	hull = Node3D.new()
	hull.name = "Orugas"
	owner.add_child(hull)
	_treads()
	upper = Node3D.new()
	upper.name = "Torso"
	upper.top_level = true
	owner.add_child(upper)
	_torso()
	show(0.0, 0.0, 0.0)


## LO MUESTRA: la puerta del horno abierta `opened` (0 a 1) hasta `angle` grados, y la ira `fury` (0 a 1).
func show(opened: float, angle: float, fury: float) -> void:
	door.rotation.x = deg_to_rad(angle) * smoothstep(0.0, 1.0, opened)
	_fire.emission_energy_multiplier = lerpf(0.4, 2.5, maxf(opened, fury * 0.6))
	if absf(fury - _shown_fury) < 0.002:
		return
	_shown_fury = fury
	_paint.albedo_color = COLOR.lerp(RAGE_COLOR, fury)
	_trim.albedo_color = _paint.albedo_color.darkened(0.45)
	var eye := EYE.lerp(RAGE_EYE, fury)
	_eye.albedo_color = eye
	_eye.emission = eye
	_eye.emission_energy_multiplier = 2.0
	_fire.albedo_color = FIRE
	_fire.emission = FIRE
	for emitter in smoke:
		emitter.emitting = fury > 0.5


## Dónde está la boca del horno (mundo): el punto débil.
func furnace() -> Vector3:
	return (door.get_parent() as Node3D).global_transform * (door.position + Vector3(0.0, -FURNACE.y * 0.5, 0.4))


## ── LAS ORUGAS ───────────────────────────────────────────────────────────────────────────────────────────────────

func _treads() -> void:
	for side: float in [-1.0, 1.0]:
		var x := side * (WAIST.x * 0.5 + TRACK.x * 0.5 + 1.5)
		Clay.box(hull, TRACK, Vector3(x, TRACK.y * 0.5, 0.0), Clay.DARK)
		_paint_part(Clay.box(hull, Vector3(TRACK.x + 0.3, 1.0, TRACK.z * 0.85), Vector3(x, TRACK.y + 0.2, 0.0), COLOR),
			_trim)
		for i in 5:
			Clay.cylinder(hull, 2.0, TRACK.x + 0.4, Vector3(x, 2.4, -TRACK.z * 0.4 + i * TRACK.z * 0.2),
				Clay.METAL.darkened(0.2), Vector3(0.0, 0.0, 90.0))
	_paint_part(Clay.box(hull, Vector3(WAIST.x + 3.0, 3.5, TRACK.z * 0.7), Vector3(0.0, 4.5, 0.0), COLOR), _trim)
	Clay.cylinder(hull, WAIST.x * 0.45, HIP - 6.0, Vector3(0.0, 6.0 + (HIP - 6.0) * 0.5, 0.0), Clay.METAL.darkened(0.3))


## ── LO DE ARRIBA ─────────────────────────────────────────────────────────────────────────────────────────────────

func _torso() -> void:
	_paint_part(Clay.box(upper, Vector3(WAIST.x + 6.0, 6.0, WAIST.z), Vector3.ZERO, COLOR), _trim)
	# Encorvado desde la cintura.
	var bent := Node3D.new()
	bent.basis = Basis(Vector3.RIGHT, -deg_to_rad(HUNCH))
	upper.add_child(bent)
	_paint_part(Clay.box(bent, WAIST, Vector3(0.0, WAIST.y * 0.5 + 0.5, 0.0), COLOR), _trim)
	var chest_at := Vector3(0.0, WAIST.y + CHEST.y * 0.5, 0.0)
	_paint_part(Clay.box(bent, CHEST, chest_at, COLOR), _paint)
	_paint_part(Clay.box(bent, Vector3(CHEST.x * 0.6, CHEST.y * 0.3, 0.6),
		chest_at + Vector3(0.0, CHEST.y * 0.28, -CHEST.z * 0.5), COLOR), _trim)
	_furnace(bent, chest_at + Vector3(0.0, -CHEST.y * 0.12, -CHEST.z * 0.5))
	_arms(bent, chest_at)
	# LA CABEZA, hundida entre los hombros, con el visor.
	var head := chest_at + Vector3(0.0, CHEST.y * 0.5 + 0.3, -CHEST.z * 0.3)
	_paint_part(Clay.box(bent, Vector3(5.0, 3.0, 4.0), head, COLOR), _trim)
	_paint_part(Clay.box(bent, Vector3(4.0, 0.8, 0.3), head + Vector3(0.0, 0.2, -2.05), EYE), _eye)
	# LAS CHIMENEAS, atrás, con su humo (prendido con ira).
	var back := chest_at + Vector3(0.0, CHEST.y * 0.1, CHEST.z * 0.5)
	for side: float in [-1.0, 1.0]:
		var stack := back + Vector3(side * CHEST.x * 0.25, CHEST.y * 0.3, 1.5)
		Clay.cylinder(bent, 1.2, 7.0, stack + Vector3.UP * 3.0, Clay.DARK)
		var emitter := ParticleSystems.chimney_smoke(ParticleMeshes.Kind.SPHERE, 2.5)
		(emitter.process_material as ParticleProcessMaterial).color = Color(0.16, 0.16, 0.17)
		emitter.local_coords = false
		emitter.emitting = false
		emitter.position = stack + Vector3.UP * 6.8
		bent.add_child(emitter)
		smoke.append(emitter)


## EL HORNO: un marco, la boca que brilla (más abierta o con ira) y la puerta con la bisagra arriba.
func _furnace(bent: Node3D, front: Vector3) -> void:
	var mouth := front + Vector3(0.0, -FURNACE.y * 0.5, 0.0)
	Clay.box(bent, Vector3(FURNACE.x + 1.2, FURNACE.y + 1.2, 0.5), mouth + Vector3(0.0, 0.0, -0.1), Clay.DARK)
	_paint_part(Clay.box(bent, Vector3(FURNACE.x, FURNACE.y, 0.3), mouth + Vector3(0.0, 0.0, -0.3), FIRE), _fire)
	# Unas barras, para que se lea como horno.
	for i in 4:
		Clay.box(bent, Vector3(0.3, FURNACE.y, 0.3), mouth + Vector3(-FURNACE.x * 0.375 + i * FURNACE.x * 0.25, 0.0, -0.5),
			Clay.DARK.darkened(0.3))
	var hinge := Node3D.new()
	hinge.name = "Bisagra"
	hinge.position = front + Vector3(0.0, 0.0, -0.75)
	bent.add_child(hinge)
	door = Node3D.new()
	door.name = "Puerta"
	hinge.add_child(door)
	_paint_part(Clay.box(door, Vector3(FURNACE.x + 0.8, FURNACE.y + 0.6, 0.5), Vector3(0.0, -FURNACE.y * 0.5, 0.0), COLOR),
		_trim)
	Clay.box(door, Vector3(FURNACE.x * 0.7, 0.4, 0.3), Vector3(0.0, -FURNACE.y * 0.75, -0.35), Clay.METAL)
	# La puerta gira en su bisagra: es la de `hinge`; la que se mueve, el nodo de la puerta.
	door = hinge


## LOS BRAZOS, en guardia: la hombrera, el brazo, el codo, el antebrazo y el puño, cuadrados. Cuelgan derecho (contra lo
## encorvado), un poco adelante.
func _arms(bent: Node3D, chest_at: Vector3) -> void:
	var straight := Basis(Vector3.RIGHT, deg_to_rad(HUNCH))
	for side: float in [-1.0, 1.0]:
		var joint := chest_at + Vector3(side * (CHEST.x * 0.5 + SHOULDER.x * 0.35), CHEST.y * 0.3, 0.0)
		_paint_part(Clay.box(bent, SHOULDER, joint + Vector3(side * SHOULDER.x * 0.1, SHOULDER.y * 0.2, 0.0), COLOR),
			_paint)
		var elbow := joint + straight * Vector3(side * 0.8, -UPPER_ARM, -UPPER_ARM * REACH)
		var wrist := elbow + straight * Vector3(0.0, -FOREARM * (1.0 - REACH), -FOREARM * REACH * 2.0)
		var arm := SHOULDER.x * 0.45
		_paint_part(_beam(bent, joint, elbow, arm), _trim)
		_paint_part(Clay.box(bent, Vector3.ONE * arm * 1.25, elbow, COLOR), _trim)
		_paint_part(_beam(bent, elbow, wrist, arm * 1.25), _paint)
		_paint_part(Clay.box(bent, Vector3.ONE * FIST, wrist + (wrist - elbow).normalized() * FIST * 0.5, COLOR), _trim)


func _beam(p: Node3D, from: Vector3, to: Vector3, width: float) -> MeshInstance3D:
	var along := to - from
	var part := Clay.box(p, Vector3(width, width, along.length()), (from + to) * 0.5, COLOR)
	part.basis = Basis.looking_at(along.normalized(), Vector3.UP if absf(along.normalized().y) < 0.95 else Vector3.BACK)
	return part


func _paint_part(part: MeshInstance3D, material: StandardMaterial3D) -> void:
	part.material_override = material
