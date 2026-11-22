class_name CageBoarding
extends ActivatableInteractable

## SUBIRSE A LA MECA JAULA CON LA E (16/11/2026; el usuario: «no vamos a hacer de que se puedan sentar directamente,
## sino que… se sientan básicamente apretando en la meca y apretando E, y que se llenen por orden… primero al lugar de
## control, después al lugar de los brazos y después al lugar de artillería… con el numpad o los números comunes de 1 a 3
## cambie de posición… el dummy sí está como ocupando el asiento, pero cuando yo me meto es como que lo saco»):
##   · E APUNTANDO A LA MECA: el primer puesto libre en `ORDER` (manejo, brazos, artillero). Un puesto con un maniquí
##     cuenta como libre: el maniquí se va (CageCabin.evict) y el que entra se sienta en su silla, la de siempre.
##   · SENTADO, 1 A 3 (fila de números o numpad): pasa a ese puesto, si está libre.
##   · SENTADO, E: se para, como en cualquier silla. Al dejar un puesto, vuelve un maniquí (CageCabin.seat_back).
## Las sillas son las de siempre (SeatInteractable): este nodo sólo elige cuál.

## Los puestos, en el orden en que se llenan (índices de CageCabin.chairs).
const ORDER := [CageCabin.DRIVER, CageCabin.LOCOMOTION, CageCabin.GUNNER]
const NUMBER_KEYS := {KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_KP_1: 0, KEY_KP_2: 1, KEY_KP_3: 2}
## Con la cámara isométrica, la E las busca por cercanía (ver InteractionDetector._iso_pick).
const GROUP := "cage_boarding"

var cabin: CageCabin = null
## El puesto donde estaba sentado el jugador en el último paso (−1, ninguno): al dejarlo, vuelve su maniquí.
var _player_post := -1


func _init() -> void:
	name = "Subirse"
	add_to_group(GROUP)


func can_interact() -> bool:
	return _next() >= 0


## Con la cámara isométrica se resalta la meca entera (ver InteractionDetector, `iso`); en primera persona, nada.
func get_outline_targets() -> Array[Node]:
	var targets: Array[Node] = []
	var player := DesignSandbox.player_of(get_tree())
	if is_instance_valid(player) and is_instance_valid(player.player_controller) \
			and is_instance_valid(player.player_controller.iso_view):
		targets.append(get_parent())
	return targets


func activate(actor: Node = null) -> void:
	var post := _next()
	if is_instance_valid(actor) and post >= 0:
		_take(actor, post)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not NUMBER_KEYS.has(key.physical_keycode):
		return
	var player := DesignSandbox.player_of(get_tree())
	var now := _post_of(player)
	var wanted: int = ORDER[NUMBER_KEYS[key.physical_keycode]]
	if now < 0 or wanted == now or not _free(wanted):
		return
	cabin.chairs[now].activate(player)
	_take(player, wanted)
	get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if cabin == null:
		return
	var now := _post_of(DesignSandbox.player_of(get_tree()))
	if _player_post >= 0 and now != _player_post:
		cabin.seat_back(_player_post)
	_player_post = now


## Saca al maniquí del puesto y sienta a `actor` en su silla.
func _take(actor: Node, post: int) -> void:
	cabin.evict(post)
	cabin.chairs[post].activate(actor)


## El primer puesto libre, en orden; −1 si no hay.
func _next() -> int:
	if cabin == null:
		return -1
	for post: int in ORDER:
		if _free(post):
			return post
	return -1


## Libre: nadie sentado, o un maniquí. Un puesto que esta meca no tiene (es para menos: CageShape.crew), no.
func _free(post: int) -> bool:
	if post >= cabin.chairs.size():
		return false
	var who := cabin.chairs[post].occupant()
	return who == null or cabin.dummies.has(who)


## El puesto donde está sentado `bi`, o −1.
func _post_of(bi: Node) -> int:
	if cabin == null or not is_instance_valid(bi):
		return -1
	for post: int in ORDER:
		if post < cabin.chairs.size() and cabin.chairs[post].occupant() == bi:
			return post
	return -1
