class_name MechAim
extends Node

## LA MIRA DE LAS HABILIDADES (22/11/2026; el usuario: «con una tecla lo disparas y moviendo el mouse lo encaminas… nunca
## haciendo clic»). Mientras se aprieta una habilidad, o hay un misil propio volando, el mouse mueve un cuadrado en el
## piso. Se guarda relativo a la meca, así no se queda atrás cuando camina. Cada máquina tiene la suya y se la cuenta a las
## demás: la ametralladora sigue la de quien la aprieta, y cada misil la de quien lo lanzó.

## A cuántos metros al frente del torso aparece.
const START := 8.0
const SEND_RATE := 20.0
const RETICLE_SIDE := 1.2
const RETICLE_BAR := 0.12
const RETICLE_LIFT := 0.08

var crew: MechCrew = null
## Dónde apunta cada máquina (peer → metros desde la meca, en el piso).
var _offsets := {}
var _on := false
var _clock := 0.0
var _reticle: Node3D = null
## LA ZONA DE LA HABILIDAD QUE ESTÁ USANDO ESTA MÁQUINA, en el piso (tecla → su marca).
var _zones := {}


func _ready() -> void:
	name = "Mira"
	multiplayer.peer_disconnected.connect(_forget)
	_reticle = _make_reticle()
	add_child(_reticle)


func _forget(peer: int) -> void:
	_offsets.erase(peer)


## ADÓNDE APUNTA `peer` (mundo), o Vector3.INF si no está apuntando.
func point_of(peer: int) -> Vector3:
	if not _offsets.has(peer):
		return Vector3.INF
	return crew.mech.global_position + (_offsets[peer] as Vector3)


## Pone la mira de `peer` a `offset` metros de la meca.
func store(peer: int, offset: Vector3) -> void:
	_offsets[peer] = Vector3(offset.x, 0.0, offset.z).limit_length(MechSkills.reach_limit())


## LO QUE SE MOVIÓ EL MOUSE (píxeles): la mira acompaña al mouse en la pantalla, compensando lo inclinado de la cámara.
func move(relative: Vector2) -> void:
	var me := multiplayer.get_unique_id()
	if not _offsets.has(me):
		return
	var view := IsoSettings.current
	var camera := IsoView.of(get_tree())
	var per_pixel := (camera.size if camera != null else view.zoom) / maxf(get_viewport().get_visible_rect().size.y, 1.0) * HitSettings.current.aim_sensitivity
	var screen := Vector2(relative.x, -relative.y / maxf(sin(deg_to_rad(view.pitch)), 0.1))
	store(me, (_offsets[me] as Vector3) + view.screen_to_world(screen) * per_pixel)


func _input(event: InputEvent) -> void:
	if _on and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		move((event as InputEventMouseMotion).relative)


func _process(_delta: float) -> void:
	for slot in MechCrew.SHOWN:
		_preview(slot)


## DIBUJA LA ZONA DE `slot` mientras alguien la mantiene: sale de la meca hacia su mira; la del misil, en la mira.
func _preview(slot: int) -> void:
	# CON CLIC, EL ARMA TOMADA (o el escudo prendido) muestra su zona aunque no esté tirando: se apunta antes de disparar.
	var taken := crew.clicking() and slot != MechCrew.ARM_LEFT and slot != MechCrew.ARM_RIGHT and crew.aimer_of(slot) != 0
	# SÓLO LA VE QUIEN LA ESTÁ USANDO, Y SÓLO MIENTRAS LA USA (22/11/2026; el usuario: «así no hacen tanto ruido visual»).
	var mine := crew.aimer_of(slot) == multiplayer.get_unique_id()
	var zone := crew.zone_of(slot) if mine and (crew.works(slot) or taken) else {}
	# El escudo sólo muestra su zona mientras está prendido: sin energía se corta y no queda el dibujo.
	if slot == MechCrew.SHIELD and not crew.mech.shield.on:
		zone = {}
	var mark := _zones.get(slot) as BossZone
	if zone.is_empty():
		if mark != null:
			mark.visible = false
		return
	if mark == null:
		mark = BossZone.skill(self, MechSkills.TINT)
		_zones[slot] = mark
	mark.visible = true
	mark.shape = zone["shape"]
	mark.size = zone["size"]
	mark.length = zone["length"]
	var way := crew.mech.guns.gun_way() if slot == MechCrew.MINIGUN else crew.way_of(slot)
	var body := crew.mech.global_position
	var floor_y := body.y - Mech.standing_height(crew.mech.cabin_shape)
	var from := Vector3(body.x, floor_y, body.z)
	if slot == MechCrew.MINIGUN:
		from = crew.mech.guns.gun_floor(floor_y)
	if slot == MechCrew.MISSILES:
		var point := point_of(crew.aimer_of(slot))
		from = Vector3(point.x, floor_y, point.z) if point.is_finite() else from + way * START
	mark.place(from, way)


func _physics_process(delta: float) -> void:
	var wanted := crew.local_aboard() and (crew.aiming_locally() or _missile_flying())
	if wanted != _on:
		_switch(wanted)
	if not _on:
		return
	var floor_y := crew.mech.global_position.y - Mech.standing_height(crew.mech.cabin_shape)
	if crew.clicking():
		_follow_pointer(floor_y)
	var point := point_of(multiplayer.get_unique_id())
	_reticle.global_position = Vector3(point.x, floor_y + RETICLE_LIFT, point.z)
	_clock -= delta
	if _clock <= 0.0 and NetFollow.online(self):
		_clock = 1.0 / SEND_RATE
		_tell.rpc(_offsets[multiplayer.get_unique_id()])


## CON CLIC, LA MIRA ES EL MOUSE, en el piso. Arriba de un cuadrado se queda donde estaba.
func _follow_pointer(floor_y: float) -> void:
	var camera := IsoView.of(get_tree())
	if camera == null or get_viewport().gui_get_hovered_control() != null:
		return
	var at := camera.pointed_at(floor_y)
	if at.is_finite():
		store(multiplayer.get_unique_id(), at - crew.mech.global_position)


func _switch(on: bool) -> void:
	_on = on
	_reticle.visible = on
	var me := multiplayer.get_unique_id()
	if on:
		store(me, Basis(Vector3.UP, crew.mech.yaw()) * Vector3.FORWARD * START)
		_clock = 0.0
	else:
		_offsets.erase(me)
		if NetFollow.online(self):
			_stop.rpc()


func _missile_flying() -> bool:
	var me := multiplayer.get_unique_id()
	for node in get_tree().get_nodes_in_group(GunnerMissile.GROUP):
		if (node as GunnerMissile).launcher == me:
			return true
	return false


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _tell(offset: Vector3) -> void:
	store(multiplayer.get_remote_sender_id(), offset)


@rpc("any_peer", "call_remote", "reliable")
func _stop() -> void:
	_offsets.erase(multiplayer.get_remote_sender_id())


## UN CUADRADO HUECO, plano y blanco, que se ve por encima de todo (sólo en esta máquina).
func _make_reticle() -> Node3D:
	var root := Node3D.new()
	root.top_level = true
	root.visible = false
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.albedo_color = Color.WHITE
	paint.no_depth_test = true
	var half := RETICLE_SIDE * 0.5
	for side: Vector3 in [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]:
		var bar := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		var along_x := absf(side.z) > 0.5
		mesh.size = Vector3(RETICLE_SIDE if along_x else RETICLE_BAR, 0.01, RETICLE_BAR if along_x else RETICLE_SIDE)
		mesh.material = paint
		bar.mesh = mesh
		bar.position = side * half
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(bar)
	return root
