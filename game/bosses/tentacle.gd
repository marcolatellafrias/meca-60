class_name Tentacle
extends Node3D

## UN TENTÁCULO DEL JEFE BOLA (13/11/2026), con SU PROPIO IK, separado del de la meca (el usuario: «no me gusta el
## sistema IK que tiene la meca… hacé uno nuevo, más optimizado para esto… mantenerlo separado y modularizado»).
##
## EL IK ES UNA CURVA DE LARGO FIJO: el tentáculo es una curva (Bézier cúbica) que sale de la bola hacia afuera y entra
## al pie de arriba. Lo único que se busca es CUÁNTO SE ABRE (el largo de las dos manijas) para que la curva mida lo que
## mide el tentáculo: una búsqueda binaria, sin iteraciones de cadena ni rodillas que salten de lado. Si la bola baja,
## sobra largo y la curva se arquea para arriba; si sube, se estira. Más lejos de lo que llega, queda recto.
##
## EL PIE SON CUATRO PALETAS TRIANGULARES EN CRUZ, apoyadas en el piso. El usuario: «cuando son pies es como que están en
## modo de cruz, pero cuando son en modo hélice empiezan a girar»: la cruz es el `rotor`, que mañana gira.

## Cuántos tramos se dibujan, y el grueso del tentáculo en la bola y en el pie (radio, m).
const SEGMENTS := 12
const ROOT_RADIUS := 1.5
const TIP_RADIUS := 0.7
## Cuántas muestras mide la curva y cuántas vueltas da la búsqueda.
const SAMPLES := 16
const SEARCHES := 14
## El pie: el cubo del medio (radio y alto, m) y cada paleta (ancho de la base, largo y grueso, m).
const HUB_RADIUS := 1.3
const HUB_HEIGHT := 1.2
const BLADE := Vector3(2.6, 5.0, 0.45)

## La cruz del pie: gira sobre su eje (mañana, la hélice).
var rotor: Node3D = null

var _pieces: Array[Node3D] = []
var _joints: Array[Node3D] = []
var _foot: Node3D = null


func _ready() -> void:
	top_level = true
	global_transform = Transform3D()
	for i in SEGMENTS:
		var radius := lerpf(ROOT_RADIUS, TIP_RADIUS, (i + 0.5) / SEGMENTS)
		_pieces.append(Clay.limb(self, radius, 1.0, Vector3.ZERO, Clay.METAL.darkened(0.15)))
		if i > 0:
			_joints.append(Clay.sphere(self, radius * 1.05, Vector3.ZERO, Clay.METAL.darkened(0.3)))
	_foot = Node3D.new()
	add_child(_foot)
	Clay.cylinder(_foot, HUB_RADIUS, HUB_HEIGHT, Vector3.UP * HUB_HEIGHT * 0.5, Clay.DARK)
	rotor = Node3D.new()
	rotor.position = Vector3.UP * BLADE.z * 0.5
	_foot.add_child(rotor)
	var blade := PrismMesh.new()
	blade.size = BLADE
	for i in 4:
		# El triángulo del prisma apunta a su +Y y su grueso va en Z: la punta, hacia afuera; el grueso, para arriba.
		var out := Vector3.FORWARD.rotated(Vector3.UP, i * PI * 0.5)
		var part := MeshInstance3D.new()
		part.mesh = blade
		part.material_override = Clay.material(Clay.YELLOW.darkened(0.25) if i == 0 else Clay.METAL.lightened(0.15))
		part.transform = Transform3D(Basis(out.cross(Vector3.UP), out, Vector3.UP),
			out * (HUB_RADIUS * 0.6 + BLADE.y * 0.5))
		rotor.add_child(part)


## LO POSA: sale de `root` hacia `out` (en la bola) y llega al pie apoyado en `tip` (el punto del piso), mirando a
## `foot_yaw`; `length` es lo que mide.
func pose(root: Vector3, out: Vector3, tip: Vector3, foot_yaw: float, length: float) -> void:
	_foot.global_transform = Transform3D(Basis(Vector3.UP, foot_yaw), tip)
	var end := tip + Vector3.UP * HUB_HEIGHT
	var handle := Tentacle.fit(root, out, end, length)
	var previous := root
	for i in SEGMENTS:
		var next := Tentacle.at(root, out, end, handle, float(i + 1) / SEGMENTS)
		var along := next - previous
		var size := maxf(along.length(), 0.001)
		var up := Vector3.UP if absf(along.normalized().dot(Vector3.UP)) < 0.95 else Vector3.BACK
		_pieces[i].global_transform = Transform3D(Basis.looking_at(along / size, up).scaled_local(Vector3(1.0, 1.0, size)),
			(previous + next) * 0.5)
		if i < SEGMENTS - 1:
			_joints[i].global_position = next
		previous = next


## EL IK: cuánto se abren las manijas (m) para que la curva de `root` (saliendo hacia `out`) a `end` (entrando de arriba)
## mida `length`. Si no llega ni recta, 0.
static func fit(root: Vector3, out: Vector3, end: Vector3, length: float) -> float:
	if root.distance_to(end) >= length:
		return 0.0
	var low := 0.0
	var high := length * 2.0
	for i in SEARCHES:
		var middle := (low + high) * 0.5
		if Tentacle.measure(root, out, end, middle) < length:
			low = middle
		else:
			high = middle
	return (low + high) * 0.5


## Lo que mide la curva con las manijas de `handle` (m).
static func measure(root: Vector3, out: Vector3, end: Vector3, handle: float) -> float:
	var total := 0.0
	var previous := root
	for i in SAMPLES:
		var next := Tentacle.at(root, out, end, handle, float(i + 1) / SAMPLES)
		total += previous.distance_to(next)
		previous = next
	return total


## Un punto de la curva, de 0 (en la bola) a 1 (en el pie).
static func at(root: Vector3, out: Vector3, end: Vector3, handle: float, share: float) -> Vector3:
	var a := root + out * handle
	var b := end + Vector3.UP * handle
	var rest := 1.0 - share
	return rest * rest * rest * root + 3.0 * rest * rest * share * a + 3.0 * rest * share * share * b \
		+ share * share * share * end
