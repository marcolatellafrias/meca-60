class_name BossRolling
extends BodyLegs

## LAS ORUGAS O LAS RUEDAS DE UNA MECA ENEMIGA (13/11/2026) — TRABAJO EN CURSO, sólo dibujo. Un chasis en el piso, debajo
## del apoyo del péndulo y mirando como el torso, unido a la caja por un pilar; las ruedas giran con lo que avanza y, en
## las orugas, los tacos corren. Caída, el chasis va pegado a la caja.

## Cuántos tacos por oruga.
const CLEATS := 10

var design: BossDesign = null

var _chassis: Node3D = null
var _strut: Node3D = null
var _wheels: Array[Node3D] = []
var _cleats: Array[Node3D] = []
var _rolled := 0.0
var _hover := 3.0
var _length := 10.0
var _radius := 1.5


## ARMA el chasis para la caja `body_size` a `hover` del piso. Antes de entrar al árbol.
func setup(made: BossDesign, body_size: Vector3, hover: float) -> void:
	design = made
	_hover = hover
	_length = body_size.z * 1.15
	_radius = hover * (0.45 if made.legs == BossDesign.Legs.TREADS else 0.62)


func _ready() -> void:
	top_level = true
	var colors := design.colors()
	_chassis = Node3D.new()
	add_child(_chassis)
	var width := body_size().x
	var plate := Vector3(width * 0.6, _hover * 0.3, _length * 0.7)
	Clay.box(_chassis, plate, Vector3(0.0, _radius * 1.1, 0.0), colors["limb"])
	_strut = Clay.limb(self, width * 0.12, 1.0, Vector3.ZERO, colors["limb"])
	if design.legs == BossDesign.Legs.TREADS:
		for side: float in [-1.0, 1.0]:
			var x := side * (width * 0.5 - _radius * 0.4)
			var track := Vector3(_radius * 1.6, _radius * 2.0, _length)
			Clay.box(_chassis, Vector3(track.x * 0.9, track.y * 0.7, track.z * 0.85), Vector3(x, _radius, 0.0), colors["limb"])
			for z: float in [-1.0, 1.0]:
				var end := Clay.cylinder(_chassis, _radius, track.x, Vector3(x, _radius, z * (_length * 0.5 - _radius)),
					colors["joint"], Vector3(0.0, 0.0, 90.0))
				_wheels.append(end)
			for i in CLEATS:
				var cleat := Clay.box(_chassis, Vector3(track.x * 1.02, 0.35, 0.5), Vector3.ZERO, colors["joint"])
				cleat.set_meta("x", x)
				_cleats.append(cleat)
	else:
		for z: float in [-1.0, 1.0]:
			for side: float in [-1.0, 1.0]:
				var wheel := Clay.cylinder(_chassis, _radius, _radius * 0.9,
					Vector3(side * (width * 0.5 + _radius * 0.2), _radius, z * _length * 0.33), colors["joint"],
					Vector3(0.0, 0.0, 90.0))
				# Los rayos: una barra que se ve girar.
				Clay.box(wheel, Vector3(_radius * 1.7, _radius * 0.95, _radius * 0.35), Vector3.ZERO, colors["accent"])
				_wheels.append(wheel)


func body_size() -> Vector3:
	return body.size if body != null else Vector3(10, 8, 10)


func replant() -> void:
	pass


func place(_k: BodySettings, delta: float) -> void:
	var standing := body.state == BalanceBody.State.STANDING and body.grounded
	var yaw := body.yaw()
	var turn := Basis(Vector3.UP, yaw)
	if standing:
		_chassis.global_transform = Transform3D(turn, body.support)
	else:
		_chassis.global_transform = body.global_transform * Transform3D(Basis(), Vector3(0.0, -body.size.y * 0.5 - _hover, 0.0))
	# LO QUE AVANZA, hacia adelante del torso: gira las ruedas y corre los tacos.
	var ahead := body.support_speed.dot(-turn.z) if standing else 0.0
	_rolled += ahead * delta
	for wheel in _wheels:
		wheel.rotation.x = -_rolled / _radius
	var spacing := (_length * 2.0) / CLEATS
	for i in _cleats.size():
		var cleat := _cleats[i]
		var around := fposmod(i * spacing - _rolled, _length * 2.0)
		var straight := _length - _radius * 2.0
		var z := 0.0
		var y := 0.0
		# Abajo va para atrás; arriba, para adelante (una vuelta aplanada).
		if around < _length:
			z = -straight * 0.5 + clampf(around, 0.0, straight)
			y = 0.15 if around < straight else _radius
		else:
			z = straight * 0.5 - clampf(around - _length, 0.0, straight)
			y = _radius * 2.0 - 0.15
		cleat.position = Vector3(float(cleat.get_meta("x")), y, z)
	var top := _chassis.global_transform * Vector3(0.0, _radius * 1.1, 0.0)
	var bottom := body.global_transform * Vector3(0.0, -body.size.y * 0.5, 0.0)
	_strut.transform = MechBody.segment(top, bottom, turn.z)
	_strut.scale = Vector3(1.0, 1.0, maxf(top.distance_to(bottom), 0.1))
