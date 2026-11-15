extends Node3D

## IDEAS PARA EL PRIMER PISO DE LA MECA DEL VÓRTICE, MAQUETAS DE ARCILLA (15/11/2026, el usuario: «la meca vieja… se
## sentía más como una fortaleza… con esta meca es como que está todo muy abierto arriba… aburrido todo el cilindro en la
## parte de arriba… algunos elementos para manejarla sean un poco más sobresalidos, no mucho porque no quiero cortar el
## flujo… accesorios que van más parados en el borde… la parte de atrás… más elevada… como si cortaras un cilindro en
## diagonal… un escaloncito y después sigue parada atrás»). Con las medidas de la meca de verdad (VortexCabin: 11 m de
## disco, 3 m de planta baja, el núcleo); la planta baja, cerrada; tres personas de verdad arriba.
##   1 · la de ahora, para comparar;
##   2 · atrás elevada con un escalón (el piso y el borde suben juntos);
##   3 · el cilindro cortado en diagonal: el borde sube parejo hacia atrás; el piso, con el escalón;
##   4 · los puestos sobresalen: el manejo, un púlpito en la proa; los brazos, columnas; las armas, en postes;
##   5 · almenas: el borde alterna dientes altos y huecos bajos, y las armas van en los huecos;
##   6 · proa y popa: adelante un borde bajo con vidrio; atrás, un muro alto (la escalera queda resguardada);
##   7 · las costillas del domo: arcos que salen del borde y se juntan arriba (el campo de fuerza, apenas);
##   8 · la 2 con los puestos de la 4 (sin costillas: el usuario, «sin costillas»);
##   9 · la 8 con los puestos sobre el borde (el usuario: «los puestos terminen donde termina el borde, no que hagas
##       puestos doblando el borde, siguen siendo elementos distintos»): piezas aparte, apoyadas arriba del borde y de su
##       mismo ancho, sin meterse en el piso por donde se camina. *Primero fue el borde mismo subiendo en cada puesto.*
##   tools/godot_ventana.sh res://tests/vortex_ideas_look.tscn -- --salida=C:/carpeta --idea=2

const VIEW := Vector2i(1280, 720)
const OUTER := 5.5
const WALK := OUTER - 0.45
const RIM_OUT := 1.0
const RIM_IN := 0.8
const CORE := 0.85
const SLAB := 0.25
const CLEAR := 3.0
## El piso de abajo del disco, sobre el suelo (las piernas, de arcilla, cortas: es la maqueta del primer piso).
const BOTTOM := 4.0
## La escalera: de qué ángulo a cuál (desde el frente, hacia la derecha) y su franja; el hueco de arriba, el último tramo.
const STAIR_FROM := PI / 3.0
const STAIR_TO := PI * 25.0 / 18.0
const STAIR_IN := 3.2
const STAIR_OUT := 5.0
const HOLE_FROM := PI * 0.8
## Atrás elevada: desde qué z (hacia atrás, +) y cuánto sube.
const CHORD := 1.2
const RAISE := 0.6
const NAMES := {
	1: "la de ahora",
	2: "atrás elevada, con un escalón",
	3: "el cilindro cortado en diagonal",
	4: "los puestos sobresalen",
	5: "almenas",
	6: "proa baja con vidrio, popa con muro",
	7: "las costillas del domo",
	8: "la 2, con los puestos de la 4",
	9: "la 8, con los puestos sobre el borde",
}

const METAL := Color(0.55, 0.57, 0.6)
const DARK_METAL := Color(0.3, 0.31, 0.34)
const DECK := Color(0.72, 0.73, 0.75)
const RAISED := Color(0.66, 0.67, 0.7)
const HOLE := Color(0.18, 0.18, 0.2)
const RED := Color(0.8, 0.22, 0.18)
const YELLOW := Color(0.93, 0.75, 0.16)
const FACE := Color(0.92, 0.9, 0.84)

var _folder := ""
var _idea := 1
var _eye: Camera3D = null
var _title: Label = null
var _glass := StandardMaterial3D.new()


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--idea="):
			_idea = int(argument.trim_prefix("--idea="))
	get_window().size = VIEW
	_glass.albedo_color = Color(0.6, 0.8, 0.92, 0.25)
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_stage()
	_build()
	var floor1 := _floor1()
	for crew: Array in [[0.0, EntityArchetype.Archetype.buff], [deg_to_rad(290.0), EntityArchetype.Archetype.lanky],
			[deg_to_rad(40.0), EntityArchetype.Archetype.fat_athletic]]:
		var angle: float = crew[0]
		var reach := (WALK - 1.15 if _raised_consoles() and angle == 0.0 else _rim_in(angle) - 0.55)
		PeopleArchetype.spawn(self, crew[1], _out(angle) * reach + Vector3(0, floor1, 0), -angle)
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(OUTER + 2.5, 0.0, -2.0), -PI * 0.6)
	await get_tree().create_timer(3.0).timeout
	_title.text = "%d. %s" % [_idea, NAMES[_idea]]
	var shots: Array = []
	for view: Array in [
			[Vector3(-11.0, floor1 + 7.0, -13.0), Vector3(0.0, floor1, 0.0), 45.0],
			[Vector3(10.0, floor1 + 7.5, 13.0), Vector3(0.0, floor1, 0.0), 45.0],
			[Vector3(-14.0, floor1 + 1.5, 2.0), Vector3(0.0, floor1 + 0.5, 0.0), 45.0],
			[Vector3(-1.5, floor1 + 1.7, -WALK + 1.6), Vector3(0.5, floor1 + 0.9, 3.0), 80.0]]:
		_look(view[0], view[1], view[2])
		shots.append(await _grab())
	_save(shots)
	get_tree().quit()


func _floor1() -> float:
	return BOTTOM + SLAB + CLEAR + SLAB


func _out(angle: float) -> Vector3:
	return Vector3(sin(angle), 0.0, -cos(angle))


func _back_raised() -> bool:
	return _idea in [2, 3, 8, 9]


func _raised_consoles() -> bool:
	return _idea in [4, 8]


func _ribs() -> bool:
	return _idea == 7


## Si el punto del borde en `angle` (a radio `reach`) está en la parte elevada de atrás.
func _is_back(angle: float, reach: float) -> bool:
	return _back_raised() and -cos(angle) * reach > CHORD


## Hasta dónde llega el borde hacia adentro.
func _rim_in(_angle: float) -> float:
	return WALK


## EL ALTO DEL BORDE (sobre el primer piso) en `angle`, por afuera; por adentro, `RIM_OUT - RIM_IN` menos.
func _rim_top(angle: float) -> float:
	var z := -cos(angle)
	match _idea:
		3:
			# En diagonal: de RIM_OUT adelante a RIM_OUT + 1,4 atrás, parejo.
			return RIM_OUT + 1.4 * (z + 1.0) * 0.5
		5:
			# Almenas: 16 dientes; los huecos, bajos.
			var tooth := int(floor(fposmod(angle + PI / 16.0, TAU) / (TAU / 16.0)))
			return RIM_OUT + (0.8 if tooth % 2 == 1 else 0.0)
		6:
			if absf(angle_difference(angle, 0.0)) < deg_to_rad(40.0):
				return 0.6
			if absf(angle_difference(angle, PI)) < deg_to_rad(70.0):
				return 2.3
			return RIM_OUT
	return RIM_OUT + (RAISE if _is_back(angle, OUTER) else 0.0)


## ── LA MECA ──────────────────────────────────────────────────────────────────────────────────────────────────────

func _build() -> void:
	var floor1 := _floor1()
	# La planta baja, cerrada; el piso de arriba, con el hueco de la escalera; el núcleo.
	_revolve([Vector2(0.0, BOTTOM), Vector2(OUTER - 0.15, BOTTOM), Vector2(OUTER, BOTTOM + 0.15), Vector2(OUTER, floor1)],
		METAL)
	_revolve([Vector2(WALK, floor1), Vector2(0.0, floor1)], DECK)
	_sector(STAIR_IN, STAIR_OUT, HOLE_FROM, STAIR_TO, floor1 + 0.01, HOLE)
	# Los escalones que se ven por el hueco, bajando.
	for i in 5:
		var a0 := lerpf(HOLE_FROM, STAIR_TO, i / 5.0)
		_sector(STAIR_IN + 0.05, STAIR_OUT - 0.05, a0, a0 + (STAIR_TO - HOLE_FROM) / 5.0, floor1 - 0.35 * (5 - i),
			Color(0.62, 0.55, 0.42))
	if _back_raised():
		_raised_back(floor1)
	_rim(floor1)
	_revolve([Vector2(CORE, floor1), Vector2(CORE, floor1 + 1.9), Vector2(CORE - 0.15, floor1 + 2.05),
		Vector2(0.0, floor1 + 2.05)], DARK_METAL.lightened(0.15))
	var deck := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = WALK
	cylinder.height = 0.2
	shape.shape = cylinder
	shape.position.y = floor1 - 0.1
	deck.add_child(shape)
	add_child(deck)
	_stations(floor1)
	if _ribs():
		_dome_ribs(floor1)
	_legs()
	# El vórtice: la boca, debajo.
	_revolve([Vector2(1.3, BOTTOM - 0.3), Vector2(0.82, BOTTOM - 0.05), Vector2(0.82, BOTTOM)], Color(0.36, 0.3, 0.5))


## ATRÁS ELEVADA: el trozo de círculo detrás de `CHORD`, `RAISE` más alto, con su escalón; el hueco de la escalera queda
## en él (oscuro).
func _raised_back(floor1: float) -> void:
	var points := PackedVector2Array()
	var half := acos(CHORD / WALK)
	for i in 33:
		var angle := PI - half + 2.0 * half * i / 32.0
		var at := _out(angle) * WALK
		points.append(Vector2(at.x, at.z))
	_prism(points, floor1, floor1 + RAISE, RAISED)
	_sector(STAIR_IN, STAIR_OUT, maxf(HOLE_FROM, PI - half), STAIR_TO, floor1 + RAISE + 0.01, HOLE)
	# El canto del escalón, marcado.
	var edge := Clay.box(self, Vector3(2.0 * sqrt(WALK * WALK - CHORD * CHORD), 0.06, 0.12),
		Vector3(0.0, floor1 + RAISE - 0.03, CHORD + 0.06), YELLOW.darkened(0.3))
	edge.name = "Canto"


## EL BORDE: por afuera, la pared hasta `_rim_top`; arriba, el bevel hacia adentro; por adentro, la cara hasta el piso
## (o hasta la parte elevada). En la 6, adelante un vidrio sobre el borde bajo.
func _rim(floor1: float) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 192
	for s in sides:
		var a0 := TAU * s / sides
		var a1 := TAU * (s + 1) / sides
		var t0 := floor1 + _rim_top(a0)
		var t1 := floor1 + _rim_top(a1)
		var bevel := RIM_OUT - RIM_IN
		var in0 := t0 - bevel
		var in1 := t1 - bevel
		var r0 := _rim_in(a0)
		var r1 := _rim_in(a1)
		var low0 := floor1 + (RAISE if _is_back(a0, WALK) else 0.0)
		var low1 := floor1 + (RAISE if _is_back(a1, WALK) else 0.0)
		_quad(tool, _out(a0) * OUTER + Vector3(0, floor1, 0), _out(a1) * OUTER + Vector3(0, floor1, 0),
			_out(a1) * OUTER + Vector3(0, t1, 0), _out(a0) * OUTER + Vector3(0, t0, 0))
		_quad(tool, _out(a0) * OUTER + Vector3(0, t0, 0), _out(a1) * OUTER + Vector3(0, t1, 0),
			_out(a1) * r1 + Vector3(0, in1, 0), _out(a0) * r0 + Vector3(0, in0, 0))
		_quad(tool, _out(a0) * r0 + Vector3(0, in0, 0), _out(a1) * r1 + Vector3(0, in1, 0),
			_out(a1) * r1 + Vector3(0, low1, 0), _out(a0) * r0 + Vector3(0, low0, 0))
	tool.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	var paint := Clay.material(METAL).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = paint
	add_child(mesh)
	if _idea == 6:
		var span := deg_to_rad(40.0)
		var steps := 12
		for i in steps:
			var a0 := -span + 2.0 * span * i / steps
			var a1 := -span + 2.0 * span * (i + 1) / steps
			var pane := MeshInstance3D.new()
			var box := BoxMesh.new()
			var p0 := _out(a0) * (OUTER - 0.1)
			var p1 := _out(a1) * (OUTER - 0.1)
			box.size = Vector3(p0.distance_to(p1) + 0.02, 1.0, 0.04)
			pane.mesh = box
			pane.material_override = _glass
			pane.position = (p0 + p1) * 0.5 + Vector3(0, floor1 + 0.6 + 0.5, 0)
			pane.rotation.y = -(a0 + a1) * 0.5
			add_child(pane)


## LOS PUESTOS: el manejo adelante, los mandos de los brazos a los costados, las ametralladoras y los enchufes vacíos.
func _stations(floor1: float) -> void:
	for station: Array in [[0.0, "drive"], [deg_to_rad(70.0), "arm"], [deg_to_rad(290.0), "arm"],
			[deg_to_rad(40.0), "gun"], [deg_to_rad(320.0), "gun"], [deg_to_rad(100.0), "socket"],
			[deg_to_rad(260.0), "socket"]]:
		var angle: float = station[0]
		var kind: String = station[1]
		var top := floor1 + _rim_top(angle)
		if _idea == 5 and kind in ["gun", "socket"]:
			# En las almenas, las armas van en el hueco más cercano.
			var tooth := TAU / 16.0
			angle = (floor(angle / tooth) + (0.0 if int(floor(angle / tooth)) % 2 == 0 else 1.0)) * tooth
			top = floor1 + _rim_top(angle)
		if _idea == 9:
			_rim_piece(angle, kind, top)
		elif _raised_consoles():
			_raised_station(angle, kind, floor1)
		else:
			_rim_station(angle, kind, top)


func _rim_station(angle: float, kind: String, top: float) -> void:
	var outward := _out(angle)
	if kind == "gun" or kind == "socket":
		Clay.box(self, Vector3(0.45, 0.06, 0.45), outward * (WALK + 0.32) + Vector3(0, top - 0.03, 0),
			YELLOW.darkened(0.3)).rotation.y = -angle
		if kind == "gun":
			_gun(outward * (WALK + 0.32) + Vector3(0, top, 0), angle, 0.3)
		return
	var inner := _rim_in(angle)
	var bevel := Vector2(OUTER - inner, RIM_OUT - RIM_IN)
	var up := (Vector3.UP * bevel.x - outward * bevel.y).normalized()
	var along := Vector3(cos(angle), 0.0, sin(angle))
	var plate := Node3D.new()
	plate.basis = Basis(along, up, along.cross(up))
	plate.position = outward * (inner + bevel.x * 0.45) + Vector3(0.0, top - bevel.y * 0.55, 0.0)
	add_child(plate)
	_controls(plate, kind)


## LOS PUESTOS QUE SOBRESALEN (la 4 y la 8): el manejo, un púlpito en la proa con la cara inclinada; los brazos, columnas
## con su tablero arriba; las armas, en postes más altos.
func _raised_station(angle: float, kind: String, floor1: float) -> void:
	var outward := _out(angle)
	var holder := Node3D.new()
	holder.rotation.y = -angle
	add_child(holder)
	match kind:
		"drive":
			holder.position = outward * (WALK - 0.45) + Vector3(0, floor1, 0)
			Clay.box(holder, Vector3(1.6, 1.1, 0.8), Vector3(0, 0.55, 0), METAL.darkened(0.1))
			var face := Node3D.new()
			face.position = Vector3(0, 1.15, 0.05)
			face.rotation.x = deg_to_rad(35.0)
			holder.add_child(face)
			Clay.box(face, Vector3(1.6, 0.08, 0.9), Vector3.ZERO, DARK_METAL)
			for side: float in [-1.0, 1.0]:
				Clay.cylinder(face, 0.025, 0.42, Vector3(side * 0.35, 0.24, 0.1), DARK_METAL)
				Clay.sphere(face, 0.06, Vector3(side * 0.35, 0.46, 0.1), RED)
			Clay.cylinder(face, 0.16, 0.04, Vector3(0, 0.06, -0.2), FACE)
		"arm":
			holder.position = outward * (WALK - 0.35) + Vector3(0, floor1, 0)
			Clay.box(holder, Vector3(0.55, 1.15, 0.55), Vector3(0, 0.575, 0), METAL.darkened(0.1))
			var face := Node3D.new()
			face.position = Vector3(0, 1.2, 0.0)
			face.rotation.x = deg_to_rad(25.0)
			holder.add_child(face)
			Clay.box(face, Vector3(0.75, 0.06, 0.45), Vector3.ZERO, DARK_METAL)
			for side: float in [-1.0, 1.0]:
				Clay.cylinder(face, 0.04, 0.3, Vector3(side * 0.22, 0.17, 0.0), DARK_METAL)
				Clay.box(face, Vector3(0.1, 0.1, 0.18), Vector3(side * 0.22, 0.34, 0.0), RED)
		"gun", "socket":
			holder.position = outward * (WALK + 0.32) + Vector3(0, floor1 + _rim_top(angle), 0)
			Clay.cylinder(holder, 0.14, 0.7, Vector3(0, 0.35, 0), DARK_METAL)
			Clay.box(holder, Vector3(0.45, 0.06, 0.45), Vector3(0, 0.72, 0), YELLOW.darkened(0.3))
			if kind == "gun":
				_gun(holder.position + Vector3(0, 0.72, 0), angle, 0.3)


## UN PUESTO SOBRE EL BORDE (la 9): una pieza aparte, del ancho del borde, apoyada arriba de él; su cara de mandos mira
## hacia adentro, inclinada. El manejo, ancho; los brazos, angostos y un poco más altos; las armas, en un pie corto.
func _rim_piece(angle: float, kind: String, top: float) -> void:
	var depth := OUTER - WALK
	var holder := Node3D.new()
	holder.position = _out(angle) * (WALK + depth * 0.5) + Vector3(0, top, 0)
	holder.rotation.y = -angle
	add_child(holder)
	if kind == "gun" or kind == "socket":
		Clay.box(holder, Vector3(0.6, 0.3, depth), Vector3(0, 0.15, 0), METAL.darkened(0.12))
		Clay.box(holder, Vector3(0.45, 0.06, 0.4), Vector3(0, 0.33, 0), YELLOW.darkened(0.3))
		if kind == "gun":
			_gun(holder.global_position + Vector3(0, 0.36, 0), angle, 0.2)
		return
	var wide := 1.6 if kind == "drive" else 0.7
	var tall := 0.55 if kind == "drive" else 0.7
	Clay.box(holder, Vector3(wide, tall, depth), Vector3(0, tall * 0.5, 0), METAL.darkened(0.12))
	var face := Node3D.new()
	face.position = Vector3(0, tall + 0.02, 0.0)
	face.rotation.x = deg_to_rad(-30.0)
	holder.add_child(face)
	Clay.box(face, Vector3(wide, 0.05, depth), Vector3.ZERO, DARK_METAL)
	_controls(face, kind)


func _controls(plate: Node3D, kind: String) -> void:
	if kind == "drive":
		for side: float in [-1.0, 1.0]:
			Clay.box(plate, Vector3(0.16, 0.06, 0.24), Vector3(side * 0.2, 0.03, 0.0), DARK_METAL)
			Clay.cylinder(plate, 0.025, 0.42, Vector3(side * 0.2, 0.24, 0.0), DARK_METAL)
			Clay.sphere(plate, 0.06, Vector3(side * 0.2, 0.46, 0.0), RED)
		return
	Clay.box(plate, Vector3(0.7, 0.05, 0.3), Vector3(0.0, 0.025, 0.0), DARK_METAL)
	for side: float in [-1.0, 1.0]:
		Clay.cylinder(plate, 0.04, 0.3, Vector3(side * 0.22, 0.17, 0.0), DARK_METAL)
		Clay.box(plate, Vector3(0.1, 0.1, 0.18), Vector3(side * 0.22, 0.34, 0.0), RED)
	Clay.cylinder(plate, 0.13, 0.04, Vector3(0.0, 0.04, 0.0), FACE)


func _gun(at: Vector3, angle: float, post: float) -> void:
	var gun := Node3D.new()
	gun.position = at
	gun.rotation.y = -angle
	add_child(gun)
	Clay.cylinder(gun, 0.07, post, Vector3(0.0, post * 0.5, 0.0), DARK_METAL)
	Clay.box(gun, Vector3(0.24, 0.24, 0.6), Vector3(0.0, post + 0.1, -0.05), DARK_METAL)
	Clay.cylinder(gun, 0.05, 0.85, Vector3(0.0, post + 0.12, -0.75), DARK_METAL, Vector3(90.0, 0.0, 0.0))
	Clay.box(gun, Vector3(0.5, 0.3, 0.04), Vector3(0.0, post + 0.2, -0.38), METAL)
	for side: float in [-1.0, 1.0]:
		Clay.cylinder(gun, 0.03, 0.2, Vector3(side * 0.13, post + 0.08, 0.3), YELLOW, Vector3(90.0, 0.0, 0.0))


## LAS COSTILLAS DEL DOMO (la 7 y la 8): seis arcos que salen del borde y se juntan arriba, con el domo apenas visible.
func _dome_ribs(floor1: float) -> void:
	var apex := Vector3(0, floor1 + 6.0, 0)
	for i in 6:
		var angle := TAU * i / 6.0 + PI / 6.0
		var foot := _out(angle) * (OUTER - 0.1) + Vector3(0, floor1 + _rim_top(angle), 0)
		var bend := _out(angle) * (OUTER * 0.75) + Vector3(0, floor1 + 4.6, 0)
		var last := foot
		for k in range(1, 13):
			var t := k / 12.0
			var point := foot.lerp(bend, t).lerp(bend.lerp(apex, t), t)
			_bar(last, point, 0.09, DARK_METAL)
			last = point
	Clay.sphere(self, 0.35, apex, DARK_METAL)
	var dome := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = OUTER
	sphere.height = OUTER * 1.1
	sphere.is_hemisphere = true
	dome.mesh = sphere
	var faint := StandardMaterial3D.new()
	faint.albedo_color = Color(0.55, 0.75, 1.0, 0.07)
	faint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	faint.cull_mode = BaseMaterial3D.CULL_DISABLED
	faint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dome.material_override = faint
	dome.position = Vector3(0, floor1 + 1.0, 0)
	add_child(dome)


func _legs() -> void:
	for side: float in [-1.0, 1.0]:
		var hip := Vector3(side * 2.2, BOTTOM - 0.2, 0.0)
		var foot := Vector3(side * 2.6, 0.35, 0.0)
		var knee := (hip + foot) * 0.5 + Vector3(0, 0, -0.6)
		Clay.sphere(self, 0.8, hip, DARK_METAL)
		_bar(hip, knee, 0.6, METAL)
		Clay.sphere(self, 0.55, knee, DARK_METAL)
		_bar(knee, foot, 0.5, METAL)
		Clay.box(self, Vector3(1.4, 0.7, 2.2), foot + Vector3(0, 0, -0.3), DARK_METAL)
		var shoulder := Vector3(side * (OUTER + 0.5), BOTTOM + 1.6, 0.0)
		var elbow := shoulder + Vector3(side * 0.6, -2.2, 0.4)
		var fist := elbow + Vector3(-side * 0.2, -0.5, -1.6)
		Clay.sphere(self, 0.7, shoulder, DARK_METAL)
		_bar(shoulder, elbow, 0.45, METAL)
		_bar(elbow, fist, 0.42, METAL)
		Clay.box(self, Vector3(1.0, 1.0, 1.1), fist, DARK_METAL)


## ── LAS PIEZAS ───────────────────────────────────────────────────────────────────────────────────────────────────

func _bar(a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var part := Clay.limb(self, radius, a.distance_to(b), (a + b) * 0.5, color)
	part.basis = Basis.looking_at(b - a, Vector3.RIGHT if absf((b - a).normalized().y) > 0.9 else Vector3.UP)


func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	tool.set_smooth_group(4294967295)
	for point: Vector3 in [a, b, c, a, c, d]:
		tool.add_vertex(point)


## UNA VUELTA de un perfil (`r`, `y`): suave alrededor, con aristas en el perfil.
func _revolve(profile: Array, color: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 64
	for s in sides:
		var a0 := TAU * s / sides
		var a1 := TAU * (s + 1) / sides
		for p in profile.size() - 1:
			var p0: Vector2 = profile[p]
			var p1: Vector2 = profile[p + 1]
			var edge := p1 - p0
			var normal := Vector2(edge.y, -edge.x).normalized()
			var quad := [[p0, a0], [p1, a0], [p1, a1], [p0, a1]]
			for corner: int in [0, 1, 2, 0, 2, 3]:
				var point: Vector2 = quad[corner][0]
				var away := _out(quad[corner][1])
				tool.set_normal(away * normal.x + Vector3.UP * normal.y)
				tool.add_vertex(away * point.x + Vector3.UP * point.y)
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = paint
	add_child(mesh)


## Una tapa plana de anillo, de `r0` a `r1`, entre dos ángulos, a la altura `y` (el hueco, los escalones).
func _sector(r0: float, r1: float, a0: float, a1: float, y: float, color: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pieces := 24
	for k in pieces:
		var b0 := lerpf(a0, a1, float(k) / pieces)
		var b1 := lerpf(a0, a1, float(k + 1) / pieces)
		_quad(tool, _out(b0) * r0 + Vector3(0, y, 0), _out(b1) * r0 + Vector3(0, y, 0), _out(b1) * r1 + Vector3(0, y, 0),
			_out(b0) * r1 + Vector3(0, y, 0))
	tool.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = paint
	add_child(mesh)


## Un prisma de borde `points` (convexo, en planta: x, z), de `y0` a `y1`.
func _prism(points: PackedVector2Array, y0: float, y1: float, color: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= points.size()
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		_quad(tool, Vector3(center.x, y1, center.y), Vector3(a.x, y1, a.y), Vector3(b.x, y1, b.y), Vector3(center.x, y1,
			center.y))
		_quad(tool, Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y))
	tool.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = paint
	add_child(mesh)


func _stage() -> void:
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -40.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.85, 0.86, 0.9)
	world.environment.ambient_light_energy = 1.0
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 1000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 40)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)


func _look(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)


func _save(shots: Array) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var first: Image = shots[0]
	var w := first.get_width() / 2
	var h := first.get_height() / 2
	var sheet := Image.create(w * 2, h * ceili(shots.size() / 2.0), false, first.get_format())
	for index in shots.size():
		var shot: Image = shots[index]
		shot.resize(w, h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/vortice_idea_%d.png" % [_folder, _idea]
	sheet.save_png(path)
	print("CAPTURA ", path)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
