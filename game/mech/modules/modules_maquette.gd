class_name ModulesMaquette
extends RefCounted

## LA MECA POR MÓDULOS, MAQUETA CAMINABLE A ESCALA REAL (16/11/2026; el bloqueo 76 de tests/modules_look, sin las paredes
## divisorias). El usuario: «sacá las paredes divisorias entre vestíbulo y hombros y cabina artillería y pasámelo a esta
## maqueta a escala real en una parcela al principio del sandbox así veo cómo se siente».
##   · ARTILLERÍA adelante, del ancho del vestíbulo, con dos sillas lado a lado; abierta al vestíbulo. La arista de
##     arriba y adelante, bajada; el frente, ese chanfle y el techo, de vidrio. LOS BRAZOS, una ventana adelante.
##   · EL VESTÍBULO, de dos brazos de largo; adelante, abierto a los dos BRAZOS (sus paredes divisorias no están);
##     atrás, a cada lado, la MUNICIÓN maciza con su boca de recarga.
##   · LA CABEZA arriba, centrada sobre toda la meca: un domo sobre un tramo corto de cilindro, cerrada (sin acceso
##     todavía).
##   · EL SUCCIONADOR sigue al vestíbulo de su mismo ancho, sin pared: el piso se termina y abajo, la boca.
## 16/11, más grande y más cuadrada vista de arriba: «aumentar… el ancho del vestíbulo y el largo también… 3 módulos de
## largo de lo de munición o brazos… el del frente sí se ensancharía para igualar el vestíbulo, pero el de cabeza no…
## un formato un poquito más cuadrado». Las celdas de los costados (brazo y munición) son cuadradas, CELLS por lado: el
## brazo adelante y la munición en las demás; artillería y el succionador más cortos para cuadrar la planta.
## Con gente sentada en cada silla (de arcilla) y una persona parada en el suelo al lado (de arcilla, para que no se caiga), para la escala.
## Todo con choque (pisos, paredes, techos): se recorre volando en modo creativo. Piernas y brazos de arcilla, sin choque.

const LIMBS := 0.8
const WIDTH := 4.0
const GUNNER_LONG := 1.6
const ARM := Vector2(1.8, 1.8)
const CELLS := 3
## Artillería: el alto del frente de vidrio (de ahí sube el chanfle) y cuánto fondo ocupa el chanfle.
const GUNNER_NOSE := 1.3
const GUNNER_SLOPE := 1.1
## La ventana del frente de cada brazo: ancho y alto, y a qué altura del piso empieza.
const ARM_WINDOW := Vector2(1.2, 1.1)
const ARM_WINDOW_FROM := 0.9
## La cabeza: el radio del domo y el alto del tramo de cilindro debajo.
const HEAD_RADIUS := 1.7
const HEAD_DRUM := 0.6
const TALL := 2.7
const SILL := 0.4
const ROOF := 0.15
const WALL := 0.12
const PACK_LONG := 1.2
const PACK_DROP := 1.2
const NOZZLE := 0.26

const GUNNER_COLOR := Color(0.85, 0.5, 0.3)
const LOBBY_COLOR := Color(0.7, 0.7, 0.66)
const ARM_COLOR := Color(0.45, 0.7, 0.4)
const HEAD_COLOR := Color(0.4, 0.6, 0.85)
const PACK_COLOR := Color(0.55, 0.42, 0.7)
const AMMO_COLOR := Color(0.85, 0.72, 0.3)
const SEAT := Color(0.25, 0.42, 0.7)
const SKIN := Color(0.86, 0.66, 0.5)
const RIM := Color(0.22, 0.23, 0.25)
const JOINT := Color(0.36, 0.375, 0.4)
const GLASS := Color(0.62, 0.8, 0.92, 0.28)
const SUCTION := Color(0.45, 0.35, 0.65, 0.25)


## Cuánto ocupa en el suelo (ancho, fondo), con los brazos y los pies.
static func footprint() -> Vector2:
	return Vector2(24.0, 24.0)


## Arma la maqueta colgada de `parent`, centrada y apoyada en y = 0.
static func build(parent: Node3D) -> Node3D:
	var root := StaticBody3D.new()
	root.name = "ModulesMaquette"
	parent.add_child(root)
	var body := MechBody.current
	var hip_line := (body.WAIST - body.HIP_DROP) * LIMBS
	var bottom := hip_line + 0.66
	var floor_y := bottom + SILL
	var top := floor_y + TALL + ROOF
	var half := WIDTH * 0.5
	var lobby_long := ARM.y * CELLS
	# Todo corrido hacia atrás para que la meca quede centrada en la parcela.
	var shift := Vector3(0.0, 0.0, -(lobby_long + PACK_LONG - GUNNER_LONG) * 0.5)
	var at := func(p: Vector3) -> Vector3: return p + shift
	var solid := func(size: Vector3, p: Vector3, color: Color) -> void:
		Clay.solid(root, size, at.call(p), color)
	# LOS PISOS: artillería, el vestíbulo y los brazos (losas macizas de la panza al piso).
	solid.call(Vector3(WIDTH, SILL, GUNNER_LONG), Vector3(0.0, bottom + SILL * 0.5, -GUNNER_LONG * 0.5),
		GUNNER_COLOR.darkened(0.15))
	solid.call(Vector3(WIDTH, SILL, lobby_long), Vector3(0.0, bottom + SILL * 0.5, lobby_long * 0.5),
		LOBBY_COLOR.darkened(0.15))
	for s: float in [-1.0, 1.0]:
		solid.call(Vector3(ARM.x, SILL, ARM.y), Vector3(s * (half + ARM.x * 0.5), bottom + SILL * 0.5, ARM.y * 0.5),
			ARM_COLOR.darkened(0.15))
	# LOS TECHOS.
	solid.call(Vector3(WIDTH, ROOF, lobby_long), Vector3(0.0, top - ROOF * 0.5, lobby_long * 0.5), LOBBY_COLOR)
	for s: float in [-1.0, 1.0]:
		solid.call(Vector3(ARM.x, ROOF, ARM.y), Vector3(s * (half + ARM.x * 0.5), top - ROOF * 0.5, ARM.y * 0.5),
			ARM_COLOR)
	var wall_y := floor_y + TALL * 0.5
	# ARTILLERÍA: la arista de arriba y adelante, bajada (un chanfle); el frente, el chanfle y el techo, de vidrio; los
	# costados, macizos con esa forma; atrás, abierta al vestíbulo. Dos sillas lado a lado.
	var nose := floor_y + GUNNER_NOSE
	var slope_end := -GUNNER_LONG + GUNNER_SLOPE
	solid.call(Vector3(WIDTH, GUNNER_NOSE, 0.05), Vector3(0.0, floor_y + GUNNER_NOSE * 0.5, -GUNNER_LONG + 0.025), GLASS)
	var rise := Vector2(GUNNER_SLOPE, top - nose)
	var tilt := Basis(Vector3.RIGHT, -atan2(rise.y, rise.x))
	Clay.solid(root, Vector3(WIDTH, 0.05, rise.length()), at.call(Vector3(0.0, (nose + top) * 0.5,
		-GUNNER_LONG + GUNNER_SLOPE * 0.5)), GLASS, tilt)
	solid.call(Vector3(WIDTH, 0.05, -slope_end), Vector3(0.0, top - 0.025, slope_end * 0.5), GLASS)
	# Los marcos de las aristas del vidrio.
	Clay.box(root, Vector3(WIDTH, 0.1, 0.1), at.call(Vector3(0.0, nose, -GUNNER_LONG + 0.05)), RIM)
	Clay.box(root, Vector3(WIDTH, 0.1, 0.1), at.call(Vector3(0.0, top - 0.05, slope_end)), RIM)
	for s: float in [-1.0, 1.0]:
		_side(root, at.call(Vector3(s * (half - WALL * 0.5), 0.0, 0.0)), PackedVector2Array([
			Vector2(-GUNNER_LONG, floor_y), Vector2(-GUNNER_LONG, nose), Vector2(slope_end, top), Vector2(0.0, top),
			Vector2(0.0, floor_y)]), GUNNER_COLOR)
		_chair(root, at.call(Vector3(s * 0.8, floor_y, -GUNNER_LONG + 0.95)))
	# LOS BRAZOS: el frente, la pared de afuera (de ahí sale el brazo) y atrás la munición; adentro, abiertos.
	var arm_z := ARM.y * 0.5
	for s: float in [-1.0, 1.0]:
		var x := s * (half + ARM.x * 0.5)
		# El frente, con una ventana (sólo adelante): abajo, arriba, dos parantes y el vidrio.
		var sill_y := floor_y + ARM_WINDOW_FROM
		var head_y := sill_y + ARM_WINDOW.y
		var post := (ARM.x - ARM_WINDOW.x) * 0.5
		solid.call(Vector3(ARM.x, ARM_WINDOW_FROM, WALL), Vector3(x, floor_y + ARM_WINDOW_FROM * 0.5, WALL * 0.5),
			ARM_COLOR)
		solid.call(Vector3(ARM.x, top - head_y, WALL), Vector3(x, (head_y + top) * 0.5, WALL * 0.5), ARM_COLOR)
		for side: float in [-1.0, 1.0]:
			solid.call(Vector3(post, ARM_WINDOW.y, WALL), Vector3(x + side * (ARM.x - post) * 0.5,
				(sill_y + head_y) * 0.5, WALL * 0.5), ARM_COLOR)
		solid.call(Vector3(ARM_WINDOW.x, ARM_WINDOW.y, 0.04), Vector3(x, (sill_y + head_y) * 0.5, WALL * 0.5), GLASS)
		solid.call(Vector3(WALL, TALL, ARM.y), Vector3(s * (half + ARM.x - WALL * 0.5), wall_y, arm_z), ARM_COLOR)
		_chair(root, at.call(Vector3(x, floor_y, arm_z - 0.1)))
		# LA MUNICIÓN, maciza, de la panza al techo, en las celdas de atrás del brazo; el vestíbulo tiene pared hacia
		# ella, con la boca de recarga y una caja de balas al pie.
		var wx := s * (half - WALL * 0.5)
		for cell in range(1, CELLS):
			var z := ARM.y * (cell + 0.5)
			solid.call(Vector3(ARM.x, top - bottom, ARM.y), Vector3(x, (top + bottom) * 0.5, z), AMMO_COLOR)
			solid.call(Vector3(WALL, TALL, ARM.y), Vector3(wx, wall_y, z), LOBBY_COLOR)
			Clay.box(root, Vector3(0.06, 0.7, 0.9), at.call(Vector3(s * (half - WALL - 0.03), floor_y + 1.1, z)), RIM)
			Clay.box(root, Vector3(0.04, 0.5, 0.7), at.call(Vector3(s * (half - WALL - 0.07), floor_y + 1.1, z)),
				AMMO_COLOR.darkened(0.3))
		_arm(root, at.call(Vector3(s * (half + ARM.x + body.LEG_THICKNESS * LIMBS * 0.72), floor_y + TALL * 0.6, arm_z)), s)
	# LA CABEZA: un domo sobre un tramo corto de cilindro (gana altura sin ensancharse), con su marco negro abajo,
	# centrada sobre toda la meca; cerrada. Choca como un cilindro de su alto.
	var head_floor := top + 0.06
	var head_z := (-GUNNER_LONG + lobby_long + PACK_LONG) * 0.5
	var head_at: Vector3 = at.call(Vector3(0.0, head_floor, head_z))
	Clay.cylinder(root, HEAD_RADIUS, HEAD_DRUM, head_at + Vector3(0.0, HEAD_DRUM * 0.5, 0.0), HEAD_COLOR)
	Clay.cylinder(root, HEAD_RADIUS + 0.06, 0.16, head_at + Vector3(0.0, 0.08, 0.0), RIM)
	var dome := MeshInstance3D.new()
	var cap := SphereMesh.new()
	cap.radius = HEAD_RADIUS
	cap.height = HEAD_RADIUS
	cap.is_hemisphere = true
	dome.mesh = cap
	dome.material_override = Clay.material(HEAD_COLOR)
	dome.position = head_at + Vector3(0.0, HEAD_DRUM, 0.0)
	root.add_child(dome)
	var shape := CollisionShape3D.new()
	var drum := CylinderShape3D.new()
	drum.radius = HEAD_RADIUS
	drum.height = HEAD_DRUM + HEAD_RADIUS
	shape.shape = drum
	shape.position = head_at + Vector3(0.0, drum.height * 0.5, 0.0)
	root.add_child(shape)
	_chair(root, head_at + Vector3(0.0, 0.0, 0.3))
	# EL SUCCIONADOR, continuo con el vestíbulo: sin piso; sus costados, el fondo, el techo y, abajo, la boca.
	var low := bottom - PACK_DROP
	var pack_z := lobby_long + PACK_LONG * 0.5
	for s: float in [-1.0, 1.0]:
		solid.call(Vector3(WALL, top - low, PACK_LONG), Vector3(s * (half - WALL * 0.5), (top + low) * 0.5, pack_z),
			PACK_COLOR)
	solid.call(Vector3(WIDTH, top - low, WALL), Vector3(0.0, (top + low) * 0.5, lobby_long + PACK_LONG - WALL * 0.5),
		PACK_COLOR)
	solid.call(Vector3(WIDTH, bottom - low, WALL), Vector3(0.0, (bottom + low) * 0.5, lobby_long + WALL * 0.5),
		PACK_COLOR)
	solid.call(Vector3(WIDTH, ROOF, PACK_LONG), Vector3(0.0, top - ROOF * 0.5, pack_z), PACK_COLOR)
	var column := MeshInstance3D.new()
	var shaft := CylinderMesh.new()
	shaft.top_radius = (PACK_LONG - WALL * 2.0) * 0.48
	shaft.bottom_radius = shaft.top_radius * 1.3
	shaft.height = floor_y
	column.mesh = shaft
	column.material_override = Clay.material(SUCTION)
	column.position = at.call(Vector3(0.0, floor_y * 0.5, pack_z))
	root.add_child(column)
	for x: float in [-1.0, 1.0]:
		for y: float in [top - 0.55, top - 1.4]:
			Clay.cylinder(root, NOZZLE, 0.45, at.call(Vector3(x, y, lobby_long + PACK_LONG + 0.22)), RIM,
				Vector3(90.0, 0.0, 0.0))
	# Una persona parada en el suelo, al lado de la meca, para la escala.
	_standing(root, at.call(Vector3(-half - ARM.x - 2.5, 0.0, -1.0)))
	_legs(root, hip_line, bottom, at.call(Vector3(0.0, 0.0, (-GUNNER_LONG + lobby_long + PACK_LONG) * 0.5)))
	return root


## UN COSTADO MACIZO con forma (un prisma de grosor WALL en x): `profile`, el contorno convexo en (z, y), centrado en
## `at` (sólo cuentan su x y su z).
static func _side(root: StaticBody3D, at: Vector3, profile: PackedVector2Array, color: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := PackedVector3Array()
	var count := profile.size()
	for x: float in [-WALL * 0.5, WALL * 0.5]:
		for point in profile:
			points.append(Vector3(x, point.y, point.x))
	# Las dos tapas (abanicos) y las caras de alrededor; las dos caras de cada triángulo, para no pensar el orden.
	for i in range(1, count - 1):
		for cap in [0, count]:
			for tri: Array in [[cap, cap + i, cap + i + 1], [cap, cap + i + 1, cap + i]]:
				for index: int in tri:
					tool.add_vertex(points[index])
	for i in count:
		var j := (i + 1) % count
		for tri: Array in [[i, j, count + j], [i, count + j, count + i], [i, count + j, j], [i, count + i, count + j]]:
			for index: int in tri:
				tool.add_vertex(points[index])
	tool.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	mesh.material_override = Clay.material(color)
	mesh.position = Vector3(at.x, 0.0, at.z)
	root.add_child(mesh)
	var shape := CollisionShape3D.new()
	var hull := ConvexPolygonShape3D.new()
	hull.points = points
	shape.shape = hull
	shape.position = mesh.position
	root.add_child(shape)


## UNA SILLA con su tablero adelante (mirando a −Z) y alguien sentado, de arcilla: `at`, el piso debajo del asiento.
static func _chair(root: Node3D, at: Vector3) -> void:
	Clay.box(root, Vector3(0.38, 0.55, 0.24), at + Vector3(0.0, 0.76, 0.14), SKIN)
	Clay.sphere(root, 0.12, at + Vector3(0.0, 1.17, 0.12), SKIN)
	Clay.box(root, Vector3(0.34, 0.14, 0.42), at + Vector3(0.0, 0.54, -0.1), SKIN)
	for side: float in [-1.0, 1.0]:
		Clay.box(root, Vector3(0.12, 0.42, 0.12), at + Vector3(side * 0.1, 0.27, -0.28), SKIN)
		Clay.box(root, Vector3(0.1, 0.1, 0.38), at + Vector3(side * 0.24, 0.8, -0.12), SKIN)
	Clay.box(root, Vector3(0.5, 0.1, 0.48), at + Vector3(0.0, 0.42, 0.05), SEAT)
	Clay.box(root, Vector3(0.5, 0.7, 0.1), at + Vector3(0.0, 0.8, 0.3), SEAT)
	Clay.box(root, Vector3(0.08, 0.42, 0.08), at + Vector3(0.0, 0.21, 0.05), RIM)
	Clay.box(root, Vector3(0.9, 0.1, 0.35), at + Vector3(0.0, 0.75, -0.6), RIM)


## UNA PERSONA PARADA, de arcilla (1,75 m): `at`, el piso entre los pies.
static func _standing(root: Node3D, at: Vector3) -> void:
	for side: float in [-1.0, 1.0]:
		Clay.box(root, Vector3(0.14, 0.85, 0.16), at + Vector3(side * 0.1, 0.425, 0.0), SKIN)
		Clay.box(root, Vector3(0.1, 0.6, 0.1), at + Vector3(side * 0.27, 1.15, 0.0), SKIN)
	Clay.box(root, Vector3(0.4, 0.6, 0.24), at + Vector3(0.0, 1.15, 0.0), SKIN)
	Clay.sphere(root, 0.13, at + Vector3(0.0, 1.62, 0.0), SKIN)


## UN BRAZO de arcilla desde el hombro, en la pared de afuera del módulo: el antebrazo hacia adelante.
static func _arm(root: Node3D, shoulder: Vector3, side: float) -> void:
	var body := MechBody.current
	var upper := body.UPPER_ARM * LIMBS
	var fore := body.FOREARM * LIMBS
	var thick := body.LEG_THICKNESS * LIMBS
	var elbow := shoulder + Vector3(side * 0.25, -1.0, 0.25).normalized() * upper
	var hand := elbow + Vector3(0.0, -0.25, -1.0).normalized() * fore
	Clay.sphere(root, thick * 0.7, shoulder, JOINT)
	_limb(root, shoulder, elbow, thick * 0.48, Clay.METAL.darkened(0.1))
	Clay.sphere(root, thick * 0.55, elbow, JOINT)
	_limb(root, elbow, hand, thick * 0.45, Clay.METAL.darkened(0.2))
	Clay.sphere(root, thick * 0.6, hand, JOINT)


## LAS PIERNAS de arcilla, con las caderas en `center` (x, z) a la altura `hip_y`, y la columna hasta la panza.
static func _legs(root: Node3D, hip_y: float, bottom: float, center: Vector3) -> void:
	var body := MechBody.current
	var thick := body.LEG_THICKNESS * LIMBS
	var hip_x := body.HIP_X * LIMBS
	var thigh := body.THIGH * LIMBS
	var foot := body.FOOT_SIZE * LIMBS
	var z := center.z
	Clay.cylinder(root, thick * 0.43, hip_x * 2.0, Vector3(0.0, hip_y, z), JOINT, Vector3(0.0, 0.0, 90.0))
	Clay.cylinder(root, thick * 0.48, bottom - hip_y + 0.2, Vector3(0.0, (bottom + hip_y) * 0.5, z), JOINT)
	for side: float in [-1.0, 1.0]:
		var hip := Vector3(side * hip_x, hip_y, z)
		var ankle := Vector3(side * (hip_x + 0.3 * LIMBS), thick * 0.33 + foot.y * 0.5, z)
		var span := hip.distance_to(ankle)
		var bend := sqrt(maxf(thigh * thigh - span * span * 0.25, 0.0))
		var knee := (hip + ankle) * 0.5 + Vector3(0.0, 0.0, -bend)
		Clay.sphere(root, thick * 0.62, hip, JOINT)
		_limb(root, hip, knee, thick * 0.5, Clay.METAL.darkened(0.1))
		Clay.sphere(root, thick * 0.62, knee, JOINT)
		_limb(root, knee, ankle, thick * 0.5, Clay.METAL.darkened(0.2))
		Clay.sphere(root, thick * 0.53, ankle, JOINT)
		Clay.box(root, foot, Vector3(ankle.x, foot.y * 0.5, ankle.z - 0.4 * LIMBS), JOINT)


static func _limb(root: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var holder := Clay.limb(root, radius, a.distance_to(b), Vector3.ZERO, color)
	var along := (b - a).normalized()
	var up := Vector3.UP if absf(along.y) < 0.95 else Vector3.BACK
	holder.transform = Transform3D(Basis.looking_at(along, up), (a + b) * 0.5)
