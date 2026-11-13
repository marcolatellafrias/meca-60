class_name Missile
extends Node3D

## UN PROYECTIL (ver ProjectileField, que los lanza y los pasa por la red). Su vuelo es UNA TRAYECTORIA CONOCIDA, una
## función del tiempo: de dónde sale (`from`), adónde cae (`to`) y cuánto tarda (`flight`). Así cada máquina lo dibuja
## igual sin mandar nada más.
##   · EL DE MORTERO (`Kind.MORTAR`, el de los jefes de prueba): sube derecho, se va alto y CAE DE ARRIBA sobre su punto
##     (una curva de Bézier con los dos puntos del medio arriba de la salida y de la llegada).
##   · LA MARCA: desde que sale, en el piso donde va a caer hay un círculo con su borde, y adentro otro que crece hasta
##     llenarlo justo cuando cae (el usuario: «que marque con un círculo donde van a caer… como las peleas de los
##     bosses»).
##   · LA ESTELA es el humo de propulsor de la fila Partículas, en grande; la explosión, su destello, sus chispas y su
##     polvo de golpe (ParticleSystems).
##   · AL CAER avisa (`landed`). EL EMPUJÓN (`blast`) lo da sólo quien manda en la física: a cada cuerpo suelto adentro
##     de su radio le cambia la velocidad hacia afuera y un poco hacia arriba, entero en el centro y nada en el borde.
##     Es un cambio de velocidad, no una fuerza: le hace lo mismo a lo liviano que a lo pesado. A una meca, su péndulo
##     decide si se inclina o se cae.
##   · LAS DE LAS MECAS ENEMIGAS (13/11/2026; ver BossArm): la BOMBA (alta, lenta y grande), el GUIADO (su punto de
##     caída persigue a `target` hasta poco antes de caer: se esquiva cambiando de rumbo o con un dash), el OBÚS del
##     cañón (casi recto y rápido) y la BALA de la ametralladora (recta, chica, sin marca).
##   · `delay`: sale recién a los tantos segundos (una ráfaga se manda entera de una vez y cada bala sale a su hora).

signal landed

enum Kind { MORTAR, BOMB, GUIDED, SHELL, BULLET }

## LOS DE CADA CLASE: el radio de la explosión y de la marca (m), cuánto le cambia la velocidad a lo que agarra en el
## centro (m/s), qué parte de eso va hacia arriba, cuán alto sube (m), su tamaño (largo, radio) y si marca el piso.
const KINDS := {
	Kind.MORTAR: {"radius": 9.0, "push": 10.0, "up": 0.15, "height": 70.0, "length": 4.0, "thickness": 0.55, "mark": true},
	Kind.BOMB: {"radius": 16.0, "push": 13.0, "up": 0.2, "height": 90.0, "length": 5.0, "thickness": 1.4, "mark": true},
	Kind.GUIDED: {"radius": 7.0, "push": 9.0, "up": 0.15, "height": 35.0, "length": 3.5, "thickness": 0.5, "mark": true},
	Kind.SHELL: {"radius": 6.0, "push": 12.0, "up": 0.2, "height": 3.0, "length": 2.5, "thickness": 0.7, "mark": true},
	Kind.BULLET: {"radius": 2.5, "push": 1.2, "up": 0.1, "height": 0.0, "length": 1.6, "thickness": 0.18, "mark": false},
}
## EL GUIADO: a cuánto persigue su punto de caída (m/s; menos que correr con dash) y cuánto antes de caer se fija (s).
const CHASE := 13.0
const LOCK := 0.8
## La marca: su color (de fondo, el que crece y el borde) y cuán gruesa es la línea del borde (m).
const MARK_COLOR := Color(0.75, 0.3, 0.18, 0.18)
const FILL_COLOR := Color(0.8, 0.32, 0.18, 0.4)
const EDGE_COLOR := Color(0.85, 0.35, 0.2, 0.85)
const EDGE := 0.5
## El alto de la columna que agarra la explosión (m): más que una meca parada.
const COLUMN := 30.0
## Cuánto queda la estela después de caer (s): lo que dura su humo.
const LINGER := 2.0
## Las partículas, más grandes que en un auto: esto es de la escala de la meca.
const SMOKE_SIZE := 5.0
const BLAST_SIZE := 4.0

var kind := Kind.MORTAR
var from := Vector3.ZERO
var to := Vector3.ZERO
var flight := 2.5
## Cuándo sale (s), el guiado a quién persigue, y el bando que no recibe (ver AreaStrike.spares).
var delay := 0.0
var target: Node3D = null
var team := ""

var _age := 0.0
var _done := false
var _body: Node3D = null
var _trail: GPUParticles3D = null
var _mark: Node3D = null
var _fill: MeshInstance3D = null


func _ready() -> void:
	top_level = true
	var shape: Dictionary = KINDS[kind]
	_body = Node3D.new()
	add_child(_body)
	var length: float = shape["length"]
	var thickness: float = shape["thickness"]
	Clay.limb(_body, thickness, length, Vector3.ZERO, Clay.METAL.darkened(0.25))
	Clay.limb(_body, thickness * 1.02, length * 0.25, Vector3(0, 0, -length * 0.4), Clay.DARK)
	_trail = ParticleSystems.thruster_smoke(ParticleMeshes.Kind.SPHERE, SMOKE_SIZE)
	# Echa hacia su −Z: girado, echa hacia atrás del misil.
	_trail.transform = Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, length * 0.5))
	_body.add_child(_trail)
	_trail.emitting = true
	_mark = _make_mark(shape["radius"])
	_mark.visible = bool(shape["mark"])
	add_child(_mark)
	_age = -delay
	visible = delay <= 0.0
	_place()


func _physics_process(delta: float) -> void:
	_age += delta
	if _age < 0.0:
		return
	visible = true
	if is_instance_valid(target) and _age < flight - LOCK:
		var ground := Vector3(target.global_position.x, to.y, target.global_position.z)
		to = to.move_toward(ground, CHASE * delta)
	if _done:
		if _age > flight + LINGER:
			queue_free()
		return
	_place()
	if _age >= flight:
		_land()


## DÓNDE VA A LOS `seconds` de salir, y hacia dónde mira: la curva (ver arriba).
func point(seconds: float) -> Vector3:
	var share := clampf(maxf(seconds, 0.0) / maxf(flight, 0.01), 0.0, 1.0)
	var rise: float = KINDS[kind]["height"]
	var top := maxf(from.y, to.y) + rise
	var a := from
	var b := Vector3(from.x, top, from.z)
	var c := Vector3(to.x, top, to.z)
	var d := to
	var back := 1.0 - share
	return a * back * back * back + b * 3.0 * back * back * share + c * 3.0 * back * share * share + d * share * share * share


func _place() -> void:
	var here := point(_age)
	var ahead := point(_age + 0.02) - here
	_body.global_position = here
	if ahead.length_squared() > 0.000001:
		var up := Vector3.UP if absf(ahead.normalized().y) < 0.95 else Vector3.FORWARD
		_body.global_basis = Basis.looking_at(ahead, up)
	_mark.global_position = to + Vector3.UP * 0.06
	var share := clampf(_age / maxf(flight, 0.01), 0.0, 1.0)
	_fill.scale = Vector3(share, 1.0, share) if share > 0.001 else Vector3(0.001, 1.0, 0.001)


## CAE: se apaga el misil y la marca, explota y avisa. La estela queda hasta que se apaga su humo.
func _land() -> void:
	_done = true
	_body.global_position = to
	for child in _body.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).visible = false
	_trail.emitting = false
	_mark.visible = false
	_explode()
	landed.emit()


func _explode() -> void:
	var size := BLAST_SIZE * clampf(float(KINDS[kind]["radius"]) / 9.0, 0.3, 1.8)
	for make: Callable in [ParticleSystems.explosion_flash, ParticleSystems.explosion_sparks, ParticleSystems.impact_dust]:
		var burst: GPUParticles3D = make.call(ParticleMeshes.Kind.LINE if make == ParticleSystems.explosion_sparks
			else ParticleMeshes.Kind.SPHERE, size)
		# Echan hacia su −Z: para arriba.
		burst.transform = Transform3D(Basis(Vector3.RIGHT, PI * 0.5), to + Vector3.UP * 0.5)
		add_child(burst)
		burst.restart()


## EL EMPUJÓN (ver arriba): sólo lo llama quien manda en la física. Agarra la COLUMNA sobre el círculo (una meca está
## alta: su caja empieza a 7 m del piso), y lo que pesa es la distancia de costado al centro.
func blast() -> void:
	var shape: Dictionary = KINDS[kind]
	var radius: float = shape["radius"]
	var column := CylinderShape3D.new()
	column.radius = radius
	column.height = COLUMN
	for body in AreaStrike.loose_in(get_world_3d().direct_space_state, column, Transform3D(Basis(),
			to + Vector3.UP * COLUMN * 0.5)):
		if AreaStrike.spares(body, team):
			continue
		var away := body.global_position - to
		away.y = 0.0
		var near := 1.0 - clampf(away.length() / radius, 0.0, 1.0)
		# Justo en el centro, para atrás de donde mira.
		var flat := away.normalized() if away.length_squared() > 0.01 else body.global_basis.z.slide(Vector3.UP).normalized()
		var way := (flat * (1.0 - float(shape["up"])) + Vector3.UP * float(shape["up"])).normalized()
		body.apply_central_impulse(way * float(shape["push"]) * near * body.mass)


## LA MARCA EN EL PISO: el círculo de fondo, el que crece adentro y el borde. Sin sombra y sin luz: se lee igual de día
## y de noche.
func _make_mark(radius: float) -> Node3D:
	var mark := Node3D.new()
	mark.top_level = true
	var ground := CylinderMesh.new()
	ground.top_radius = radius
	ground.bottom_radius = radius
	ground.height = 0.02
	ground.radial_segments = 40
	mark.add_child(Missile.flat_part(ground, MARK_COLOR, 0.0))
	_fill = Missile.flat_part(ground, FILL_COLOR, 0.02)
	mark.add_child(_fill)
	var edge := TorusMesh.new()
	edge.inner_radius = radius - EDGE
	edge.outer_radius = radius
	edge.rings = 40
	edge.ring_segments = 4
	var ring := Missile.flat_part(edge, EDGE_COLOR, 0.04)
	ring.scale = Vector3(1.0, 0.1, 1.0)
	mark.add_child(ring)
	return mark


static func flat_part(mesh: Mesh, color: Color, lift: float) -> MeshInstance3D:
	var made := StandardMaterial3D.new()
	made.albedo_color = color
	made.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	made.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	made.no_depth_test = false
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = made
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	part.position = Vector3.UP * lift
	return part
