class_name PillarNozzles
extends Node3D

## LAS TOBERAS DEL CUBO CINEMÁTICO (13/11/2026) — PLACEHOLDER: sólo se ven, no empujan (el cubo se mueve a mano). El
## usuario: «unas toberas nuevas así como de placeholder que muestren como un impulso cuando vuelo… o cuando hago
## dashes».
##   · CUATRO ABAJO, en las esquinas, echan para abajo al volar.
##   · CUATRO A LOS COSTADOS (adelante, atrás, izquierda, derecha), a media altura: un fogonazo corto del lado contrario
##     al dash.
## Cada una tiene su llama, un cono que crece con lo que empuja y se apaga de a poco.

## Cuánto tarda una llama en apagarse (s) y cuán larga es entera (m).
const FADE := 0.35
const FLAME := 4.0
const FIRE := Color(1.0, 0.55, 0.15)

var _below: Array[Dictionary] = []
var _sides: Array[Dictionary] = []


## ARMA las toberas para una caja de ancho `size` (x, z).
func build(size: Vector3) -> void:
	var half := size * 0.5
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			_below.append(_nozzle(Vector3(x * (half.x - 0.8), 0.0, z * (half.z - 0.8)), Vector3.DOWN))
	for way: Vector3 in [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]:
		var at := Vector3(way.x * half.x, 0.0, way.z * half.z)
		var made := _nozzle(at, way)
		made["way"] = way
		_sides.append(made)


## Una tobera en `at` (en el cubo) que echa hacia `out`.
func _nozzle(at: Vector3, out: Vector3) -> Dictionary:
	var holder := Node3D.new()
	holder.position = at
	holder.basis = Basis.looking_at(out, Vector3.FORWARD if absf(out.y) > 0.9 else Vector3.UP)
	add_child(holder)
	Clay.cylinder(holder, 0.5, 0.6, Vector3(0, 0, -0.3), Clay.DARK, Vector3(90, 0, 0))
	var cone := CylinderMesh.new()
	# Ancha en la boca y fina en la punta: acostada (ver `show_flames`), su abajo queda contra la tobera.
	cone.top_radius = 0.0
	cone.bottom_radius = 0.45
	cone.height = 1.0
	cone.radial_segments = 10
	var flame := MeshInstance3D.new()
	flame.mesh = cone
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(FIRE, 0.85)
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame.material_override = glow
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(flame)
	return {"holder": holder, "flame": flame, "throttle": 0.0}


## Dónde van, según el alto de ahora: las de abajo, al ras; las de los costados, a media altura.
func fit(height: float) -> void:
	for nozzle in _sides:
		(nozzle["holder"] as Node3D).position.y = height * 0.5


## VUELA: las de abajo, a `share` (0 a 1).
func fly(share: float) -> void:
	for nozzle in _below:
		nozzle["throttle"] = maxf(float(nozzle["throttle"]), share)


## DASH hacia `way` (en el cubo): se prenden las que echan para el otro lado.
func dash(way: Vector3) -> void:
	for nozzle in _sides:
		var along := -(nozzle["way"] as Vector3).dot(way.normalized())
		if along > 0.3:
			nozzle["throttle"] = 1.0


## Cada paso: las llamas, del largo de lo que empujan; y se apagan de a poco.
func show_flames(delta: float) -> void:
	for nozzle in _below + _sides:
		var throttle := float(nozzle["throttle"])
		var flame := nozzle["flame"] as MeshInstance3D
		flame.visible = throttle > 0.02
		var length := FLAME * throttle
		# El cono acostado sobre la Z del soporte, saliendo hacia su −Z.
		flame.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5).scaled_local(Vector3(1.0, maxf(length, 0.01), 1.0)),
			Vector3(0.0, 0.0, -0.6 - length * 0.5))
		nozzle["throttle"] = move_toward(throttle, 0.0, delta / FADE)
