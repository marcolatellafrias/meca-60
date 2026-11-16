class_name ModulesMaquette
extends RefCounted

## LA MECA POR MÓDULOS, MAQUETA CAMINABLE A ESCALA REAL (16/11/2026; el bloqueo 76 de tests/modules_look, sin las paredes
## divisorias). El usuario: «sacá las paredes divisorias entre vestíbulo y hombros y cabina artillería y pasámelo a esta
## maqueta a escala real en una parcela al principio del sandbox así veo cómo se siente».
##   · ARTILLERÍA adelante, del ancho del vestíbulo, con dos sillas lado a lado; abierta al vestíbulo.
##   · EL VESTÍBULO, de dos brazos de largo; adelante, abierto a los dos BRAZOS (sus paredes divisorias no están);
##     atrás, a cada lado, la MUNICIÓN maciza con su boca de recarga.
##   · LA CABEZA arriba, alineada con los brazos, cerrada (sin acceso todavía).
##   · EL SUCCIONADOR sigue al vestíbulo de su mismo ancho, sin pared: el piso se termina y abajo, la boca.
## 16/11, más grande y más cuadrada vista de arriba: «aumentar… el ancho del vestíbulo y el largo también… 3 módulos de
## largo de lo de munición o brazos… el del frente sí se ensancharía para igualar el vestíbulo, pero el de cabeza no…
## un formato un poquito más cuadrado». Las celdas de los costados (brazo y munición) son cuadradas, CELLS por lado: el
## brazo adelante y la munición en las demás; artillería y el succionador más cortos para cuadrar la planta.
## Con gente sentada en cada silla (de arcilla) y una persona parada en el suelo al lado (de arcilla, para que no se caiga), para la escala.
## Todo con choque (pisos, paredes, techos): se recorre volando en modo creativo. Piernas y brazos de arcilla, sin choque.

const LIMBS := 0.65
const WIDTH := 4.0
const GUNNER_LONG := 1.6
const ARM := Vector2(1.8, 1.8)
const CELLS := 3
const HEAD := Vector2(1.6, 1.8)
const TALL := 2.7
const HEAD_TALL := 1.7
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
const SUCTION := Color(0.45, 0.35, 0.65, 0.25)


## Cuánto ocupa en el suelo (ancho, fondo), con los brazos y los pies.
static func footprint() -> Vector2:
	return Vector2(20.0, 20.0)


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
	solid.call(Vector3(WIDTH, ROOF, GUNNER_LONG), Vector3(0.0, top - ROOF * 0.5, -GUNNER_LONG * 0.5), GUNNER_COLOR)
	solid.call(Vector3(WIDTH, ROOF, lobby_long), Vector3(0.0, top - ROOF * 0.5, lobby_long * 0.5), LOBBY_COLOR)
	for s: float in [-1.0, 1.0]:
		solid.call(Vector3(ARM.x, ROOF, ARM.y), Vector3(s * (half + ARM.x * 0.5), top - ROOF * 0.5, ARM.y * 0.5),
			ARM_COLOR)
	var wall_y := floor_y + TALL * 0.5
	# ARTILLERÍA: el frente y sus dos costados; atrás, abierta al vestíbulo. Dos sillas lado a lado.
	solid.call(Vector3(WIDTH, TALL, WALL), Vector3(0.0, wall_y, -GUNNER_LONG + WALL * 0.5), GUNNER_COLOR)
	for s: float in [-1.0, 1.0]:
		solid.call(Vector3(WALL, TALL, GUNNER_LONG), Vector3(s * (half - WALL * 0.5), wall_y, -GUNNER_LONG * 0.5),
			GUNNER_COLOR)
		_chair(root, at.call(Vector3(s * 0.8, floor_y, -GUNNER_LONG + 0.95)))
	# LOS BRAZOS: el frente, la pared de afuera (de ahí sale el brazo) y atrás la munición; adentro, abiertos.
	var arm_z := ARM.y * 0.5
	for s: float in [-1.0, 1.0]:
		var x := s * (half + ARM.x * 0.5)
		solid.call(Vector3(ARM.x, TALL, WALL), Vector3(x, wall_y, WALL * 0.5), ARM_COLOR)
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
	# LA CABEZA, arriba de los brazos y del frente del vestíbulo: cerrada.
	var head_floor := top + 0.06
	solid.call(Vector3(HEAD.x, 0.1, HEAD.y), Vector3(0.0, head_floor - 0.05, HEAD.y * 0.5), HEAD_COLOR.darkened(0.15))
	solid.call(Vector3(HEAD.x, ROOF, HEAD.y), Vector3(0.0, head_floor + HEAD_TALL + ROOF * 0.5, HEAD.y * 0.5),
		HEAD_COLOR)
	var head_y := head_floor + HEAD_TALL * 0.5
	for z: float in [WALL * 0.5, HEAD.y - WALL * 0.5]:
		solid.call(Vector3(HEAD.x, HEAD_TALL, WALL), Vector3(0.0, head_y, z), HEAD_COLOR)
	for s: float in [-1.0, 1.0]:
		solid.call(Vector3(WALL, HEAD_TALL, HEAD.y), Vector3(s * (HEAD.x - WALL) * 0.5, head_y, HEAD.y * 0.5),
			HEAD_COLOR)
	_chair(root, at.call(Vector3(0.0, head_floor, 0.95)))
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
