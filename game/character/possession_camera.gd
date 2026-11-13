class_name PossessionCamera
extends Camera3D

## ── POSEER A UN PERSONAJE: MIRAR POR SUS OJOS (03/11/2026, lo pidió el usuario) ───────────────────────────────
## «La capacidad de poseer a los personajes para ver a través de su primera persona. Poseer hace de que no puedas
## controlar al personaje, pero puedas verlo en primera persona. Con todo lo de un personaje normal, solamente que se
## controla por guión.» Una cámara que va a los ojos de `target` con la MISMA regla que la del jugador (ver
## FirstPersonView: el balanceo por la perilla, los golpes, sentado, tirado) y mira adonde mira su intención —la que
## escribe su guion—; al poseído se le esconde la cabeza, como al jugador en primera persona. No le toca nada más: lo
## sigue manejando quien lo manejaba.
##
## Quien mira (`viewer`, el ente o el cuerpo del jugador) se apaga mientras tanto (BoneInstantiator.set_active): ni se
## mueve ni escucha teclas, y su cámara deja de ser la actual. Las teclas que no son de él —las del sandbox, la T que
## reinicia— siguen. `release` lo devuelve como estaba. Uno a la vez: poseer a otro suelta al anterior.

static var _current: PossessionCamera = null

var target: BoneInstantiator
var viewer: BoneInstantiator
var _view := FirstPersonView.new()


## QUE `viewer` MIRE POR LOS OJOS DE `target`. Si ya poseía a otro, pasa a éste (el que mira es el mismo de antes).
static func possess(target_: BoneInstantiator, viewer_: BoneInstantiator) -> void:
	if not is_instance_valid(target_) or not target_.is_inside_tree():
		return
	var keep_viewer := viewer_
	if is_instance_valid(_current):
		if is_instance_valid(_current.viewer):
			keep_viewer = _current.viewer
		_current._leave_target()
		_current.queue_free()
		_current = null
	var cam := PossessionCamera.new()
	cam.name = "Posesion"
	cam.target = target_
	cam.viewer = keep_viewer
	target_.get_tree().root.add_child(cam)
	_current = cam
	if is_instance_valid(keep_viewer) and keep_viewer != target_:
		keep_viewer.set_active(false)
	target_.set_first_person_visibility(true)
	cam.current = true
	cam._show_whom()
	cam._follow(0.0)


## VUELVE A MIRAR EL QUE MIRABA: el poseído vuelve a verse entero, y el que miraba se prende.
static func release() -> void:
	if not is_instance_valid(_current):
		_current = null
		return
	var cam := _current
	_current = null
	cam._leave_target()
	if is_instance_valid(cam.viewer):
		cam.viewer.set_active(true)
	cam.queue_free()


## El poseído ahora, o null.
static func possessed() -> BoneInstantiator:
	return _current.target if is_instance_valid(_current) and is_instance_valid(_current.target) else null


## EL SIGUIENTE de `among` (los personajes de una parcela) después del que está poseído, en ronda; el primero si no hay
## ninguno poseído de ésos. Para que apretar otra vez pase al próximo.
static func next_of(among: Array) -> BoneInstantiator:
	var alive: Array[BoneInstantiator] = []
	for node: Variant in among:
		if node is BoneInstantiator and is_instance_valid(node) and (node as BoneInstantiator).is_inside_tree():
			alive.append(node as BoneInstantiator)
	if alive.is_empty():
		return null
	var at := alive.find(possessed())
	return alive[(at + 1) % alive.size()]


func _init() -> void:
	process_priority = 1  # después de la pose de los personajes (ver PlayerController._init)


## ── A QUIÉN SE ESTÁ MIRANDO (04/11/2026, el usuario: «que me aparezca qué arquetipo estoy poseyendo… algo bien
## rudimentario»): un rótulo arriba a la izquierda con su arquetipo; se va con la cámara.
func _show_whom() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var label := Label.new()
	var arch := "?"
	if is_instance_valid(target) and target.entity_instantiation != null:
		arch = str(EntityArchetype.Archetype.keys()[int(target.entity_instantiation.archetype_type)])
	label.text = "poseído: %s  (P: el siguiente · H: salir)" % arch
	label.position = Vector2(16, 16)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	layer.add_child(label)


func _leave_target() -> void:
	if is_instance_valid(target):
		target.set_first_person_visibility(false)


func _process(delta: float) -> void:
	_follow(delta)


func _follow(delta: float) -> void:
	if not is_instance_valid(target) or not is_instance_valid(target.char_rigidbody) or not target.is_inside_tree():
		release()
		return
	# Si se reconstruyó, su cuerpo nuevo nace entero: se le vuelve a esconder la cabeza.
	if target.body_visual != _hidden_in:
		_hidden_in = target.body_visual
		target.set_first_person_visibility(true)
	global_position = _view.eye(target, delta, FirstPersonView.head_bob)
	var rb := target.char_rigidbody
	# Adonde mira: su intención si tiene quien lo maneje; si no (uno de la calle), para donde va su cápsula.
	var yaw := CharacterIntent.world_yaw(rb.frame, target.intent.look_yaw)
	var pitch := clampf(target.intent.look_pitch, -1.2, 1.2)
	if not target.kind.looks():
		var front := -rb.global_basis.z
		yaw = atan2(-front.x, -front.z)
		pitch = 0.0
	global_rotation = Vector3(pitch, yaw, 0.0)


var _hidden_in: Node = null
