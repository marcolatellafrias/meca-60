class_name IsoView
extends Camera3D

## LA CÁMARA ISOMÉTRICA (22/11/2026): sigue al jugador local, con el ángulo y el zoom de IsoSettings, arriba o abajo de la
## meca por igual. Mientras lo sigue, el jugador se maneja por pantalla (ver PlayerController.set_iso). En la partida vale
## en todos lados; en el sandbox, sólo adentro de `zone`.

const GROUP := "iso_view"
## Lo que hay detrás del personaje que se sigue dibujando, además de lo que entra en pantalla (m).
const DEPTH := 200.0
## Lo más cerca que va la cámara del personaje (m).
const MIN_AWAY := 30.0
const ZOOM_EASE := 4.0

## Dónde vale, en los ejes X y Z del padre. Vacío: en todos lados.
var zone := Rect2()

var _player: BoneInstantiator = null
## EL ZOOM DE AHORA: va suave hacia el de arriba de la meca o el de a pie (MatchSettings). En el sandbox, el de su panel.
var _zoom := -1.0


static func of(tree: SceneTree) -> IsoView:
	return tree.get_first_node_in_group(GROUP) as IsoView


func _init() -> void:
	top_level = true
	process_priority = 2


func _ready() -> void:
	add_to_group(GROUP)


func _exit_tree() -> void:
	_bind(null)


func _process(delta: float) -> void:
	var player := DesignSandbox.player_of(get_tree())
	_bind(player if _serves(player) else null)
	if not is_instance_valid(_player) or not is_instance_valid(_player.char_rigidbody):
		return
	_place(_player.char_rigidbody.global_position, delta)
	# Poseyendo algo, la cámara es la de poseer; al soltarlo vuelve ésta.
	if not current and get_tree().get_first_node_in_group("driving") == null:
		make_current()


## Dónde está el mouse en la pantalla.
func pointer() -> Vector2:
	return get_viewport().get_mouse_position()


## EL PUNTO DEL MUNDO BAJO EL MOUSE, a la altura `height`; INF si el rayo no llega a ella.
func pointed_at(height: float) -> Vector3:
	var screen := pointer()
	var from := project_ray_origin(screen)
	var way := project_ray_normal(screen)
	if absf(way.y) < 0.001:
		return Vector3.INF
	return from + way * ((height - from.y) / way.y)


func _serves(player: BoneInstantiator) -> bool:
	if not is_instance_valid(player) or not is_instance_valid(player.char_rigidbody):
		return false
	if not zone.has_area():
		return true
	var at := (get_parent() as Node3D).to_local(player.char_rigidbody.global_position)
	return zone.has_point(Vector2(at.x, at.z))


func _bind(player: BoneInstantiator) -> void:
	if player == _player:
		return
	if is_instance_valid(_player) and is_instance_valid(_player.player_controller):
		_player.player_controller.set_iso(null)
	_player = player
	if is_instance_valid(_player) and is_instance_valid(_player.player_controller):
		_player.player_controller.set_iso(self)


func _goal_zoom() -> float:
	if zone.has_area():
		return IsoSettings.current.zoom
	var game := MatchSettings.current
	return game.zoom_aboard if _player.is_seated else game.zoom_foot


func _place(aim: Vector3, delta: float) -> void:
	var knobs := IsoSettings.current
	var goal := _goal_zoom()
	_zoom = goal if _zoom < 0.0 else lerpf(_zoom, goal, 1.0 - exp(-ZOOM_EASE * delta))
	projection = Camera3D.PROJECTION_ORTHOGONAL if knobs.orthographic else Camera3D.PROJECTION_PERSPECTIVE
	size = _zoom
	fov = knobs.fov
	# A la distancia en la que la perspectiva encuadra lo mismo que la ortográfica; así el zoom es uno solo.
	var away := maxf(_zoom * 0.5 / tan(deg_to_rad(knobs.fov) * 0.5), MIN_AWAY)
	var turn := knobs.view_basis()
	global_transform = Transform3D(turn, aim + turn.z * away)
	near = 0.05
	far = away + DEPTH
