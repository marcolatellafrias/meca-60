class_name BallShell
extends RefCounted

## EL CASCO DEL JEFE BOLA (14/11/2026): UNA ESFERA LOW POLY A LA QUE SE LE SACAN LAS FRANJAS DEL MEDIO Y EN SU LUGAR VA
## LA RENDIJA, hundida. La silueta sigue siendo una esfera (y la hitbox también). El usuario: «una esfera más o menos low
## poly, agarrar una cierta cantidad de segmentos del medio y reemplazarlos por una rendija… así la forma general sigue
## siendo una esfera». *Antes eran dos medias esferas separadas por la rendija, y quedaba raro.*
## Provisorio a propósito («no hagas código tan permanente»): un solo armado, con sus números a mano.
##
## Los polos van a los costados (±X): las franjas son anillos alrededor del eje X, y la rendija queda de arriba a abajo,
## de adelante hacia atrás por arriba, por donde corre el cañón. El casco, LISO o con caras planas (`smooth`; el usuario,
## 14/11/2026: «que la esfera sea shade smooth o auto smooth»); la rendija, siempre plana, y el borde entre los dos queda
## marcado (son superficies aparte): como un auto smooth.


## LA MALLA: radio `radius`; `bands` franjas de polo a polo (par); las `slit_bands` del medio son la rendija, hundida
## `depth`; `sides` caras alrededor; el casco liso o plano (`smooth`). Dos superficies: el casco (0) y la rendija (1).
static func mesh(radius: float, bands: int, slit_bands: int, sides: int, depth: float, smooth := true) -> ArrayMesh:
	var made := ArrayMesh.new()
	var step := PI / bands
	var edge := slit_bands * 0.5 * step
	# EL CASCO: las franjas de cada lado, desde el borde de la rendija hasta el polo.
	var shell := SurfaceTool.new()
	shell.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-1.0, 1.0]:
		var outer := (bands - slit_bands) / 2
		for i in outer:
			var a := edge + i * step
			var b := edge + (i + 1) * step
			_band(shell, radius, side * a, side * b, sides, side > 0.0, smooth)
	shell.generate_normals()
	shell.commit(made)
	# LA RENDIJA: las dos paredes (del borde hacia adentro) y el fondo, un anillo hundido.
	var slit := SurfaceTool.new()
	slit.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rim_x := radius * sin(edge)
	var rim_r := radius * cos(edge)
	var floor_r := rim_r - depth
	for i in sides:
		var p0 := TAU * i / sides
		var p1 := TAU * (i + 1) / sides
		for side: float in [-1.0, 1.0]:
			# La pared: del borde del casco al fondo, mirando hacia el medio de la rendija.
			_quad(slit, _ring(side * rim_x, rim_r, p0), _ring(side * rim_x, rim_r, p1),
				_ring(side * rim_x, floor_r, p1), _ring(side * rim_x, floor_r, p0), side < 0.0)
		# El fondo: mirando hacia afuera.
		_quad(slit, _ring(-rim_x, floor_r, p0), _ring(-rim_x, floor_r, p1), _ring(rim_x, floor_r, p1),
			_ring(rim_x, floor_r, p0), true)
	slit.generate_normals()
	slit.commit(made)
	return made


## Una franja del casco entre las latitudes `a` y `b` (radianes, 0 en la rendija, ±π/2 en los polos).
static func _band(tool: SurfaceTool, radius: float, a: float, b: float, sides: int, flip: bool, smooth: bool) -> void:
	for i in sides:
		var p0 := TAU * i / sides
		var p1 := TAU * (i + 1) / sides
		_quad(tool, _ring(radius * sin(a), radius * cos(a), p0), _ring(radius * sin(a), radius * cos(a), p1),
			_ring(radius * sin(b), radius * cos(b), p1), _ring(radius * sin(b), radius * cos(b), p0), flip, smooth)


## Un punto a `x` sobre el eje, a `r` de él, en el ángulo `phi` alrededor.
static func _ring(x: float, r: float, phi: float) -> Vector3:
	return Vector3(x, r * cos(phi), r * sin(phi))


## Dos triángulos, con su cara hacia un lado o el otro (`flip`). Planas, cada cara con sus propios vértices; lisas
## (`smooth`), los vértices del mismo lugar comparten la normal.
static func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, flip: bool, smooth := false) -> void:
	tool.set_smooth_group(0 if smooth else -1)
	# Godot mira de frente las caras que van en el sentido de las agujas del reloj.
	var corners := [a, c, b, a, d, c] if flip else [a, b, c, a, c, d]
	for corner: Vector3 in corners:
		tool.add_vertex(corner)
