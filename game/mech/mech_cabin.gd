class_name MechCabin
extends Node3D

## LO DE TODA CABINA DE LA MECA (la cuadrada, SquareCabin; la redonda, RoundCabin): lo que se ve de la caja y por donde
## se camina adentro. Cada una arma lo suyo en su `_ready` y dice dónde va la silla de arriba (`top_seat`), cómo es su
## marco (`build_frame`) y adónde sube la U (`board`). Lo de todas, acá:
##   · LAS SILLAS (`chairs`, en el orden de `POSTS`) y los maniquíes sentados en ellas (`seat_dummies`).
##   · EL MARCO (MotionFrame): adentro se camina. Las formas de choque van en `interior`, un cuerpo que NO choca con nada:
##     es de donde el marco copia su SOMBRA. El que entra a la caja pasa a ir en el marco, que lo lleva con la meca, y
##     choca sólo con esa sombra. Y LA CAJA DE AFUERA, que es maciza y es la que choca con el mundo, deja de chocar con
##     él (`ride`).
##   · LAS PIEZAS: el vidrio (`_pane`), las barras del marco del vidrio (`_bar`), las placas con hueco y sus choques.
## *Hasta el 15/11/2026 este era también el interior de la cuadrada de antes: la tarima atrás de pared a pared con dos
## escaleras, el tablero corrido con sus divisores y la caja sin chanfles, con el vidrio y su marco armados a mano para
## cada cabeza. Se retiró (el usuario: «dale, hacé todo eso»): la cuadrada es SquareCabin.*

const SLAB := CabinGrid.SLAB
const WALL := CabinGrid.WALL
const KIT := Color(0.78, 0.27, 0.27)
## El marco del vidrio: el metal, un poco más oscuro.
const FRAME := Color(0.36, 0.38, 0.41)
const BATTERY := Color(0.93, 0.75, 0.16)
const AMMO := Color(0.47, 0.53, 0.32)
const SEAT_SCENE := "res://game/interactables/activatable/working_seat.tscn"
const DUMMY_SCENE := "res://game/character/player.tscn"
const DUMMY_BODIES: Array[EntityArchetype.Archetype] = [EntityArchetype.Archetype.fat_athletic,
	EntityArchetype.Archetype.lanky, EntityArchetype.Archetype.buff, EntityArchetype.Archetype.fat_man]
## Los puestos, en el orden de las sillas (`chairs`): los tres de adelante, de izquierda a derecha, y el de arriba.
const POSTS := ["brazo izquierdo", "espalda", "brazo derecho", "movimiento"]

var mech: Mech = null
var frame: MotionFrame = null
var lift: PelvisLift = null
var interior: StaticBody3D = null
## Las sillas (las pone cada una, en el orden de `POSTS`) y los maniquíes sentados en ellas (ver `seat_dummies`).
var chairs: Array[SeatInteractable] = []
var dummies: Array[Node3D] = []

var _riders := {}


## La silla desde la que se mira en primera persona al poseer la meca: la del movimiento, arriba (la pone cada una).
func top_seat() -> Vector3:
	return Vector3.ZERO


## EL MARCO, con sus volúmenes y su sombra (lo arma cada una, cuando la meca ya tiene todo armado).
func build_frame() -> void:
	push_error("MechCabin: la cabina %s no arma su marco" % name)


## SUBE AL JUGADOR (la U del sandbox): cada una dice adónde.
func board() -> void:
	pass


## LOS PUESTOS de las sillas de adelante (ver SeatStation, sesión Tableros). Por ahora ninguna: los puestos se apoyaban
## en el tablero de la cuadrada de antes, que se retiró; vuelven cuando pasen a la silla.
func _stations() -> void:
	pass


## UN MANIQUÍ SENTADO EN CADA SILLA, para ver la escala de adentro (el usuario, 13/11/2026: «le pondría los asientos
## reales y dejaría sentados… unos dummies. Así veo cómo se siente la escala de adentro»). Personajes de la calle, de
## varios cuerpos, que van al lado de la meca en el árbol y los lleva su silla. Los sienta la meca de brazos, no la de
## práctica.
func seat_dummies() -> void:
	var holder := mech.get_parent() as Node3D
	if holder == null:
		return
	# EL PUESTO (ver SeatStation, sesión Tableros): en cada silla de adelante con su puesto abierto. La primera silla de
	# la derecha, la del brazo derecho, queda sin maniquí, para sentarse uno con E.
	_stations()
	var free_chair: SeatInteractable = null
	for chair_found in chairs:
		if chair_found.position.x > 0.0:
			free_chair = chair_found
			break
	for i in chairs.size():
		if chairs[i] == free_chair:
			continue
		var dummy := (load(DUMMY_SCENE) as PackedScene).instantiate() as BoneInstantiator
		dummy.kind = CharacterKind.npc()
		dummy.master_seed = EntityInstantiation.debug_seed(DUMMY_BODIES[i % DUMMY_BODIES.size()], i)
		holder.add_child(dummy)
		dummies.append(dummy)
		# Aparece adentro de la caja maciza: que no la empuje antes de que el marco lo lleve (ver `ride`).
		mech.add_collision_exception_with(dummy.char_rigidbody)
		dummy.place_at(chairs[i].global_position + chairs[i].global_basis.z * 0.8, chairs[i].heading())
		dummy.intent.seat = chairs[i]


## Saca a los maniquíes (van al lado de la meca en el árbol, no adentro): para cuando la meca se cambia por otra.
func free_dummies() -> void:
	for dummy in dummies:
		if is_instance_valid(dummy):
			dummy.queue_free()
	dummies.clear()


## LA CAJA DE AFUERA NO CHOCA CON LOS QUE VAN ADENTRO: ellos ya dejaron de mirar al mundo (ver MotionFrame.join), pero
## la caja los seguía viendo. Se mira quién va en el marco en cada paso.
func ride() -> void:
	var inside := {}
	for body: Variant in frame._members.keys():
		if is_instance_valid(body) and body is PhysicsBody3D:
			inside[body] = true
			if not _riders.has(body):
				mech.add_collision_exception_with(body as PhysicsBody3D)
	for body: Variant in _riders.keys():
		if not inside.has(body) and is_instance_valid(body):
			mech.remove_collision_exception_with(body as PhysicsBody3D)
	_riders = inside


## Una barra cuadrada del marco, de `a` a `b`, centrada en la línea.
func _bar(a: Vector3, b: Vector3, thick: float) -> void:
	if a.distance_to(b) < 0.01:
		return
	var along := (b - a).normalized()
	var helper := Vector3.UP if absf(along.y) < 0.9 else Vector3.FORWARD
	var up := (helper - along * helper.dot(along)).normalized()
	var bar := Clay.box(self, Vector3(thick, thick, a.distance_to(b) + thick), (a + b) * 0.5, FRAME)
	bar.name = "Marco"
	bar.basis = Basis(up.cross(along), up, along)


## Un paño de vidrio plano, con sus esquinas en orden (un abanico desde la primera).
func _pane(corners: Array) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a: Vector3 = corners[0]
	var normal := ((corners[1] as Vector3) - a).cross((corners[2] as Vector3) - a).normalized()
	for i in range(1, corners.size() - 1):
		for point: Vector3 in [a, corners[i], corners[i + 1]]:
			tool.set_normal(normal)
			tool.add_vertex(point)
	var pane := MeshInstance3D.new()
	pane.name = "Vidrio"
	pane.mesh = tool.commit()
	var paint := StandardMaterial3D.new()
	# Su color y cuánto se ve, de la forma (el F2).
	paint.albedo_color = CabinGrid.GLASS_COLOR
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	paint.roughness = 0.2
	pane.material_override = paint
	add_child(pane)


## ── LAS PIEZAS DE PLACAS Y CHOQUES (las usan la redonda y la cuadrada) ──────────────────────────────────────────

## EL SOMBREADO, COMO EL AUTO SMOOTH DE BLENDER (el usuario, 15/11/2026: «veo que tienen shade smooth, debería ser auto
## smooth»): cada cara curva (la de afuera de un cilindro, la de adentro, el borde de un hueco redondo) es un grupo
## suave; las tapas y los cantos, planos, con su arista marcada. Ver SurfaceTool.set_smooth_group.
const FLAT := 4294967295
const SMOOTH_IN := 1
const SMOOTH_OUT := 2


func _v(point: Vector2, y: float) -> Vector3:
	return Vector3(point.x, y, point.y)


## Una forma de choque convexa en `interior`.
func _convex(points: PackedVector3Array) -> void:
	var shape := CollisionShape3D.new()
	var hull := ConvexPolygonShape3D.new()
	hull.points = points
	shape.shape = hull
	interior.add_child(shape)


## Formas de choque de un anillo entre `outer` y `inner` (de la misma cantidad de puntos), de `bottom` a `top`.
func _ring_shapes(outer: PackedVector2Array, inner: PackedVector2Array, bottom: float, top: float) -> void:
	for i in outer.size():
		var j := (i + 1) % outer.size()
		_convex(PackedVector3Array([_v(outer[i], bottom), _v(outer[j], bottom), _v(inner[i], bottom), _v(inner[j], bottom),
			_v(outer[i], top), _v(outer[j], top), _v(inner[i], top), _v(inner[j], top)]))


## UNA PLACA entre el borde `outer` y el `inner` (de la misma cantidad de puntos), de `bottom` a `top`: las dos caras y
## los dos cantos. El canto de afuera, suave si `round_outer` (un círculo) o con sus aristas (un polígono); el de
## adentro, el hueco del ascensor, siempre redondo.
func _plate(outer: PackedVector2Array, inner: PackedVector2Array, bottom: float, top: float, color: Color,
		round_outer := false) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in outer.size():
		var j := (i + 1) % outer.size()
		_quad(tool, _v(inner[i], top), _v(inner[j], top), _v(outer[j], top), _v(outer[i], top), FLAT)
		_quad(tool, _v(inner[i], bottom), _v(outer[i], bottom), _v(outer[j], bottom), _v(inner[j], bottom), FLAT)
		_quad(tool, _v(outer[i], bottom), _v(outer[i], top), _v(outer[j], top), _v(outer[j], bottom),
			SMOOTH_OUT if round_outer else FLAT)
		_quad(tool, _v(inner[i], bottom), _v(inner[j], bottom), _v(inner[j], top), _v(inner[i], top),
			SMOOTH_IN if inner_round(inner) else FLAT)
	return _mesh(tool, color)


## Si un borde es redondo (el hueco del ascensor) o un polígono (el borde de la tarima, que también va de hueco del
## escalón): todos sus puntos a la misma distancia de su centro.
func inner_round(edge: PackedVector2Array) -> bool:
	var center := Vector2.ZERO
	for point in edge:
		center += point
	center /= edge.size()
	var reach := edge[0].distance_to(center)
	for point in edge:
		if absf(point.distance_to(center) - reach) > 0.01:
			return false
	return true


func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, group: int) -> void:
	tool.set_smooth_group(group)
	for point: Vector3 in [a, b, c, a, c, d]:
		tool.add_vertex(point)


func _mesh(tool: SurfaceTool, color: Color) -> MeshInstance3D:
	tool.generate_normals()
	var part := MeshInstance3D.new()
	part.mesh = tool.commit()
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	part.material_override = paint
	return part
