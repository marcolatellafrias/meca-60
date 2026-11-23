class_name HitTarget
extends Node3D

## LO QUE SE PUEDE GOLPEAR (22/11/2026; el usuario: «algo… que tenga más control»). LOS GOLPES SON PLANOS: el juego no tiene
## verticalidad, así que un blanco es un círculo en el piso y las formas de los ataques (línea, círculo, cono) lo tocan o no,
## sin importar a qué altura vaya el tiro. Todo golpe entra por `strike`, y lo decide el host.
##   · CON `receiver` (un jefe): por ahora se le pasa el golpe como siempre, y su cabeza decide la vida.
##   · SIN `receiver` (la bolsa): la ficha (HitCard): número de daño, aguante y, si se lo rompe, empuje. Avisa `struck`, y
##     quien lo lleva dibuja la reacción: la física ya no decide nada.

signal struck(damage: float, way: Vector3, push: float, broke: bool)

const GROUP := "hit_targets"
const BODY_META := &"hit_target"
## A qué altura debajo del tiro se mira si hay una pared en el medio (m): la del cuerpo de la meca.
const SIGHT_DROP := 2.0

## Lo que sigue (su centro), su radio en el piso (o lo que lo dice, si cambia) y a quién le pasa los golpes.
var anchor: Node3D = null
var radius := 1.0
var radius_source := Callable()
var receiver: Node = null
## Dónde va el cartel del aguante, sobre el centro (m).
var bar_height := 2.6

## El aguante que le queda. Para las pruebas: lo que recibió.
var poise := 100.0
var dealt := 0.0
var hits := 0
var breaks := 0
## LO QUE LE DEJA LA MUNICIÓN ESPECIAL (fuego, carga eléctrica).
var effects: HitEffects = null

var _quiet := 99.0
var _number: DamageNumber = null
var _bar: Label3D = null


func _init() -> void:
	name = "Blanco"
	top_level = true


func _ready() -> void:
	add_to_group(GROUP)
	effects = HitEffects.new()
	effects.target = self
	add_child(effects)
	if receiver != null:
		return
	poise = HitSettings.current.bag_poise
	_bar = Label3D.new()
	_bar.top_level = true
	_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bar.no_depth_test = true
	_bar.pixel_size = 0.006
	_bar.font_size = 48
	_bar.outline_size = 10
	_bar.outline_modulate = Color.BLACK
	_bar.render_priority = 9
	add_child(_bar)
	_show_bar()


## ── LO QUE TIENE ─────────────────────────────────────────────────────────────────────────────────────────────────

## El blanco de un cuerpo (ver `bind`), o null.
static func of_body(body: Object) -> HitTarget:
	if body == null or not body.has_meta(BODY_META):
		return null
	var found: Variant = body.get_meta(BODY_META)
	return found as HitTarget if is_instance_valid(found) else null


## Lo que le pegue a `body` (un tramo de la bolsa, la caja de un jefe) le pega a este blanco.
func bind(body: Object) -> void:
	body.set_meta(BODY_META, self)


func center() -> Vector3:
	return anchor.global_position if is_instance_valid(anchor) else global_position


func flat_radius() -> float:
	return float(radius_source.call()) if radius_source.is_valid() else radius


func alive() -> bool:
	if receiver == null:
		return true
	var life := Health.of(anchor)
	return life == null or not life.dead()


## El punto del borde que da hacia `from`, a la altura de su centro: donde se ve el impacto.
func surface(from: Vector3) -> Vector3:
	var middle := center()
	var toward := Vector2(from.x - middle.x, from.z - middle.z)
	if toward.length() < 0.01:
		return middle
	toward = toward.normalized() * flat_radius()
	return middle + Vector3(toward.x, 0.0, toward.y)


## ── LAS FORMAS, EN EL PISO ───────────────────────────────────────────────────────────────────────────────────────

static func _flat(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)


## UNA LÍNEA de `from` a `to`, de `width` de cada lado: el primer blanco que toca, o null.
static func first_on_line(tree: SceneTree, from: Vector3, to: Vector3, width: float) -> HitTarget:
	var a := _flat(from)
	var b := _flat(to)
	var best: HitTarget = null
	var nearest := INF
	for node in tree.get_nodes_in_group(GROUP):
		var target := node as HitTarget
		if not target.alive():
			continue
		var middle := _flat(target.center())
		var closest := Geometry2D.get_closest_point_to_segment(middle, a, b)
		if middle.distance_to(closest) > target.flat_radius() + width:
			continue
		var along := a.distance_to(closest)
		if along < nearest:
			nearest = along
			best = target
	return best


## UN CÍRCULO: todos los blancos que toca.
static func in_circle(tree: SceneTree, at: Vector3, reach: float) -> Array[HitTarget]:
	var out: Array[HitTarget] = []
	for node in tree.get_nodes_in_group(GROUP):
		var target := node as HitTarget
		if target.alive() and _flat(target.center()).distance_to(_flat(at)) <= reach + target.flat_radius():
			out.append(target)
	return out


## UN CONO desde `from` hacia `way`, de `length` y `half` grados a cada lado: el primer blanco a la vista, o null.
static func first_in_line(tree: SceneTree, from: Vector3, way: Vector3, length: float, width: float,
		skip: Array[RID]) -> HitTarget:
	var origin := _flat(from)
	var ahead := _flat(way).normalized()
	var side := Vector2(-ahead.y, ahead.x)
	var best: HitTarget = null
	var nearest := INF
	for node in tree.get_nodes_in_group(GROUP):
		var target := node as HitTarget
		if not target.alive():
			continue
		var to := _flat(target.center()) - origin
		var distance := to.length()
		var size := target.flat_radius()
		var along := to.dot(ahead)
		if along < -size or along > length + size or absf(to.dot(side)) > width * 0.5 + size or distance >= nearest:
			continue
		if _in_sight(target, from, distance, skip):
			nearest = distance
			best = target
	return best


## UNA LÍNEA QUE ATRAVIESA: todos los blancos que toca, los que estén a la vista.
static func all_in_line(tree: SceneTree, from: Vector3, way: Vector3, length: float, width: float,
		skip: Array[RID]) -> Array[HitTarget]:
	var out: Array[HitTarget] = []
	var origin := _flat(from)
	var ahead := _flat(way).normalized()
	var side := Vector2(-ahead.y, ahead.x)
	for node in tree.get_nodes_in_group(GROUP):
		var target := node as HitTarget
		if not target.alive():
			continue
		var to := _flat(target.center()) - origin
		var size := target.flat_radius()
		var along := to.dot(ahead)
		if along >= -size and along <= length + size and absf(to.dot(side)) <= width * 0.5 + size \
				and _in_sight(target, from, to.length(), skip):
			out.append(target)
	return out


## Si no hay nada fijo entre `from` y el borde del blanco, a la altura del cuerpo.
static func _in_sight(target: HitTarget, from: Vector3, distance: float, skip: Array[RID]) -> bool:
	var low := from + Vector3.DOWN * SIGHT_DROP
	var goal := target.center()
	goal.y = low.y
	var query := PhysicsRayQueryParameters3D.create(low, goal, PhysicsLayers.FIXED, skip)
	var hit := target.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or _flat(hit["position"]).distance_to(_flat(from)) >= distance - target.flat_radius() - 0.2


## ── EL GOLPE ─────────────────────────────────────────────────────────────────────────────────────────────────────

## LE PEGA `source`, escalado por `power` (ver HitCard). `strength` es el impulso de siempre: lo que hoy mira un jefe.
func strike(source: String, power: float, strength: float, at: Vector3, way: Vector3) -> void:
	if ProjectileField.is_client(self) or not alive():
		return
	hits += 1
	if receiver != null:
		receiver.call("take_hit", strength, at, source)
		return
	var knobs := HitSettings.current
	var card := HitCard.make(source, power)
	dealt += card.damage
	_quiet = 0.0
	poise -= card.stagger
	var broke := poise <= 0.0
	if broke:
		breaks += 1
		poise = knobs.bag_poise
	var moved := card.push / maxf(knobs.bag_weight, 0.01) if broke else 0.0
	_show.rpc(card.damage, Vector3(way.x, 0.0, way.z).normalized(), moved, broke, poise)


@rpc("authority", "call_local", "reliable")
func _show(damage: float, way: Vector3, moved: float, broke: bool, poise_now: float) -> void:
	poise = poise_now
	_quiet = 0.0
	if not is_instance_valid(_number) or not _number.open():
		_number = DamageNumber.new()
		add_child(_number)
		_number.global_position = center() + Vector3.UP * (bar_height + 0.6)
	_number.add(damage, broke)
	_show_bar()
	struck.emit(damage, way, moved, broke)


func _physics_process(delta: float) -> void:
	if receiver != null:
		return
	var knobs := HitSettings.current
	_quiet += delta
	if _quiet >= knobs.poise_wait and poise < knobs.bag_poise:
		poise = minf(poise + knobs.poise_refill * delta, knobs.bag_poise)
		_show_bar()
	if _bar != null:
		_bar.global_position = center() + Vector3.UP * bar_height


func _show_bar() -> void:
	if _bar != null:
		_bar.text = Mech.bar(poise / maxf(HitSettings.current.bag_poise, 0.01))
