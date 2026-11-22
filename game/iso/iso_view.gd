class_name IsoView
extends Camera3D

## LA CÁMARA ISOMÉTRICA (22/11/2026): sigue al jugador local, con el ángulo y el zoom de IsoSettings, arriba o abajo de la
## meca por igual. Mientras lo sigue, el jugador se maneja por pantalla (ver PlayerController.set_iso). En la partida vale
## en todos lados; en el sandbox, sólo adentro de `zone`.

const GROUP := "iso_view"
## Lo que hay detrás del personaje que se sigue dibujando, además de lo que entra en pantalla (m).
const DEPTH := 200.0
## Lo más cerca que va la cámara del personaje (m), y cada cuánto se mira qué tapa (s).
const MIN_AWAY := 30.0
const CUT_EVERY := 0.1
## Cuánto se despeja alrededor del personaje (m).
const SEE_AROUND := 3.5
## Desde qué alto algo cuenta como pared (m).
const WALL_TALL := 2.5
## La capa de lo que tapa: las demás cámaras la ven, ésta no.
const HIDDEN_LAYER := 1 << 19

## Dónde vale, en los ejes X y Z del padre. Vacío: en todos lados.
var zone := Rect2()

var _player: BoneInstantiator = null
var _clock := 0.0


static func of(tree: SceneTree) -> IsoView:
	return tree.get_first_node_in_group(GROUP) as IsoView


func _init() -> void:
	top_level = true
	process_priority = 2


func _ready() -> void:
	add_to_group(GROUP)


func _exit_tree() -> void:
	_bind(null)


func _process(_delta: float) -> void:
	var player := DesignSandbox.player_of(get_tree())
	_bind(player if _serves(player) else null)
	if not is_instance_valid(_player) or not is_instance_valid(_player.char_rigidbody):
		return
	_place(_player.char_rigidbody.global_position)
	# Poseyendo algo, la cámara es la de poseer; al soltarlo vuelve ésta.
	if not current and get_tree().get_first_node_in_group("driving") == null:
		make_current()


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


func _place(aim: Vector3) -> void:
	var knobs := IsoSettings.current
	projection = Camera3D.PROJECTION_ORTHOGONAL if knobs.orthographic else Camera3D.PROJECTION_PERSPECTIVE
	size = knobs.zoom
	fov = knobs.fov
	# A la distancia en la que la perspectiva encuadra lo mismo que la ortográfica; así el zoom es uno solo.
	var away := maxf(knobs.zoom * 0.5 / tan(deg_to_rad(knobs.fov) * 0.5), MIN_AWAY)
	var turn := knobs.view_basis()
	global_transform = Transform3D(turn, aim + turn.z * away)
	near = 0.05
	far = away + DEPTH
	_clock -= get_process_delta_time()
	if _clock <= 0.0:
		_clock = CUT_EVERY
		_cut_away(aim, global_position, knobs.cut)


## ── LO QUE TAPA NO SE DIBUJA ─────────────────────────────────────────────────────────────────────────────────────────
## Dos reglas, sobre lo fijo del mundo (ni las mecas ni los personajes): LO QUE EMPIEZA MÁS ARRIBA que `cut` sobre el
## personaje (los techos, el piso de la arena visto desde la base) y LO QUE QUEDA ENTRE ÉL Y LA CÁMARA (una pared). Se
## saca de la capa que ve esta cámara, así la de los ojos y las sombras no cambian.
func _cut_away(aim: Vector3, eye: Vector3, height: float) -> void:
	cull_mask = 0xFFFFF & ~HIDDEN_LAYER
	var meshes: Array[MeshInstance3D] = []
	_collect(get_parent(), meshes)
	# Desde el piso donde está y alrededor: que no asome sólo la cabeza, y que se vea lo que tiene al lado (la meca).
	var feet := Vector3(aim.x, _floor_y(aim), aim.z)
	var back := eye - aim
	var right := global_basis.x * SEE_AROUND
	var near_way := Vector3(global_basis.z.x, 0.0, global_basis.z.z).normalized() * SEE_AROUND
	var spots: Array[Vector3] = [feet, feet + right, feet - right, feet + near_way, feet - near_way]
	for mesh in meshes:
		var box := mesh.global_transform * mesh.get_aabb()
		var hide_it := box.position.y > feet.y + height
		# Sólo lo alto (una pared): una consola o un banco delante del personaje se siguen viendo.
		if box.size.y >= WALL_TALL:
			for spot in spots:
				hide_it = hide_it or box.intersects_segment(spot + Vector3.UP * 0.1, spot + back) != null
		if hide_it and mesh.layers != HIDDEN_LAYER:
			mesh.set_meta(&"iso_layers", mesh.layers)
			mesh.layers = HIDDEN_LAYER
		elif not hide_it and mesh.has_meta(&"iso_layers"):
			mesh.layers = mesh.get_meta(&"iso_layers")
			mesh.remove_meta(&"iso_layers")


## La altura del piso: la de la meca, si va sentado en ella; si no, la de sus pies.
func _floor_y(aim: Vector3) -> float:
	if _player.is_seated:
		var at: Node = _player.current_seat
		while at != null:
			if at is BalanceBody:
				return (at as BalanceBody).support.y
			at = at.get_parent()
	return aim.y - 1.0


func _collect(node: Node, into: Array[MeshInstance3D]) -> void:
	if node is BalanceBody or node is BoneInstantiator or node is RigidBody3D:
		return
	if node is MeshInstance3D:
		into.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect(child, into)
