class_name PlayerDebug
extends Node

## ── LO DE PRUEBA DEL JUGADOR (17/11/2026) ───────────────────────────────────────────────────────────────────────────
## Sólo en un personaje con depuración (`BoneInstantiator.debug_enabled`: el jugador del juego, no el del sandbox): el
## panel de depuración (F9), tirarse al piso (G), volver a nacer con otro cuerpo (P), pasarse al cuerpo que se mira (F),
## los spawns de prueba y el panel de impactos. Lo arma el PlayerController la primera vez que se arma con depuración
## (ver PlayerController.on_skeleton_built). *Hasta el 17/11/2026 vivía adentro del PlayerController, mezclado con lo del
## jugador; lo pidió el usuario («separar lo del jugador de lo de prueba… mejores APIs, mejor estructura»).*

## LA TECLA DEL PANEL: F9, la primera de los paneles globales del sandbox (ver docs/technical/sandbox.md): de F1 a F7 son
## de las filas, y la F8 detiene el juego.
const PANEL_KEY := KEY_F9

var controller: PlayerController = null
var _panel: DebugPanel = null
var _impacts: ImpactDebugHUD = null
var _fall_rb: CharacterRigidBody3D = null


## CADA VEZ QUE SE ARMA EL CUERPO: el panel de impactos una sola vez, la caída del cuerpo nuevo y el panel, que muestra
## al personaje nuevo.
func on_skeleton_built() -> void:
	if not is_instance_valid(_impacts):
		_impacts = ImpactDebugHUD.create()
		_impacts.visible = false
		add_child(_impacts)
	_watch_fall(controller.char_rigidbody)
	_build_panel()


func _watch_fall(rb: CharacterRigidBody3D) -> void:
	if is_instance_valid(_fall_rb) and _fall_rb.fall_triggered.is_connected(_on_fall):
		_fall_rb.fall_triggered.disconnect(_on_fall)
	_fall_rb = rb
	rb.fall_triggered.connect(_on_fall)


func _on_fall(_data: Variant) -> void:
	_impacts.notify_fall_triggered()


func _bi() -> BoneInstantiator:
	return controller._get_bi()


## ── LAS TECLAS ──────────────────────────────────────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not controller.is_ready:
		return
	# El panel, siempre (también con un menú abierto); lo demás, jugando.
	if key.keycode == PANEL_KEY and is_instance_valid(_panel):
		_panel.toggle()
		return
	if not UIState.gameplay_active():
		return
	var bi := _bi()
	if not is_instance_valid(bi):
		return
	match key.keycode:
		KEY_F:
			var ic := controller.interaction_controller
			var hovered := ic.get_hovered_rb() if is_instance_valid(ic) and not bi.is_seated else null
			var target := _owner_of(hovered) if is_instance_valid(hovered) else null
			if target != null and target != bi:
				switch_to(target)
		KEY_G:
			toggle_ragdoll()
		KEY_P:
			respawn()


## ── CADA PASO: el panel de impactos, si está a la vista ─────────────────────────────────────────────────────────────
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_impacts) or not _impacts.visible or not controller.is_ready:
		return
	var rb := controller.char_rigidbody
	var bi := _bi()
	var ragdoll := bi.ragdoll_util if is_instance_valid(bi) else null
	_impacts.update_impact_debug(rb.impact_xz, rb.global_transform.basis, rb.impact_y, rb.linear_velocity,
		rb._last_impact_world_dir, rb.ragdoll_threshold, is_instance_valid(ragdoll) and ragdoll.is_active,
		is_instance_valid(ragdoll) and ragdoll.is_recovering, rb._last_impact_xz_magnitude,
		rb.top_speed, rb.ragdoll_threshold)


## ── TIRARSE, VOLVER A NACER, PASARSE A OTRO CUERPO ──────────────────────────────────────────────────────────────────

## G: al piso, o de pie si ya estaba. Levantándose no se puede volver a tirar.
func toggle_ragdoll() -> void:
	var bi := _bi()
	if not is_instance_valid(bi) or not is_instance_valid(bi.ragdoll_util):
		return
	var rb := controller.char_rigidbody
	if bi.ragdoll_util.is_active:
		bi.ragdoll_util.deactivate(rb, bi.custom_bones_util.lower_spine)
		rb.rotation.y = controller.camera_yaw
	elif not bi.ragdoll_util.is_recovering:
		_leave_seat_in_place(bi)
		bi.ragdoll_util.activate(rb, bi.custom_bones_util.lower_spine)


## P: el cuerpo se rearma con otra semilla (la del arquetipo elegido, ver DebugArchetype), donde estaba. Antes sale
## limpio de todo lo que se aferra a la cápsula: el vuelo, la silla, el piso, lo que tenía en las manos.
func respawn() -> void:
	var bi := _bi()
	if not is_instance_valid(bi):
		return
	controller.set_creative(false)
	_leave_seat_in_place(bi)
	if is_instance_valid(bi.ragdoll_util) and bi.ragdoll_util.is_active:
		bi.ragdoll_util.deactivate(controller.char_rigidbody, bi.custom_bones_util.lower_spine)
	if is_instance_valid(controller.interaction_controller):
		controller.interaction_controller.stop_all()
	var rb_before := controller.char_rigidbody
	var at := Vector3(rb_before.global_position.x, 3.0, rb_before.global_position.z)
	bi.master_seed = DebugArchetype.respawn_seed()
	bi.initialize_skeleton()  # → PlayerController.on_skeleton_built: todo se vuelve a atar
	if is_instance_valid(bi.net_sync):
		bi.net_sync.broadcast_seed()
	controller.char_rigidbody.global_position = at
	controller.char_rigidbody.rotation.y = controller.camera_yaw
	controller.reset_locomotion()


## El arquetipo con el que nace la P, y nace ya. Queda elegido: la P otra vez da otra variación del mismo.
func respawn_as(archetype: int) -> void:
	DebugArchetype.selected = archetype
	respawn()


## F: el jugador pasa al cuerpo que mira, y el que deja pasa a ser lo que era el otro (ver CharacterKind).
func switch_to(target: BoneInstantiator) -> void:
	var current := _bi()
	var yaw := controller.camera_yaw
	var mine := current.kind
	_set_kind(current, target.kind)
	_set_kind(target, mine)
	current.intent.move = Vector2.ZERO
	current.intent.sprint = false
	controller.rebind(target)
	_watch_fall(controller.char_rigidbody)
	controller.char_rigidbody.input_enabled = true
	controller.camera_yaw = yaw
	controller.char_rigidbody.rotation.y = yaw
	# En primera persona la cabeza y el torso los lleva la cámara: fuera del animador.
	for bone: CustomBone in [target.custom_bones_util.head, target.custom_bones_util.neck,
			target.custom_bones_util.chest, target.custom_bones_util.higher_spine]:
		if is_instance_valid(bone):
			target.procedural_animator.unregister_bone(bone)
	target.refresh_camera_animations()
	controller.reset_locomotion()
	controller.take_camera()
	if is_instance_valid(controller.interaction_controller):
		controller.interaction_controller.stop_all()


static func _set_kind(bi: BoneInstantiator, kind: CharacterKind) -> void:
	bi.kind = kind
	if is_instance_valid(bi.char_rigidbody):
		bi.char_rigidbody.kind = kind


static func _owner_of(node: Node) -> BoneInstantiator:
	var current := node.get_parent()
	while current != null:
		if current is BoneInstantiator:
			return current as BoneInstantiator
		current = current.get_parent()
	return null


## SALE DE LA SILLA EN EL LUGAR: tirarse y volver a nacer no conviven con estar sentado (sentada, la cápsula queda inerte
## y la silla le presta una malla), así que primero se sale. El golpe que tira no necesita esto: sentado no se cae.
static func _leave_seat_in_place(bi: BoneInstantiator) -> void:
	var seat := bi.current_seat as SeatInteractable
	if is_instance_valid(seat):
		seat.release_occupant_in_place()


## ── EL PANEL (F9) ───────────────────────────────────────────────────────────────────────────────────────────────────
func _build_panel() -> void:
	if is_instance_valid(_panel):
		_panel.queue_free()
	_panel = DebugPanel.new()
	add_child(_panel)
	var bi := _bi()
	if is_instance_valid(bi) and is_instance_valid(bi.entity_instantiation):
		_panel.add_text("Info", _stats_text(bi.entity_instantiation))
	_panel.add_info("Red", _net_text())
	_panel.add_action("Acciones", "Toggle creative (V)", func() -> void: controller.toggle_creative())
	_panel.add_action("Acciones", "Toggle ragdoll (G)", toggle_ragdoll)
	_panel.add_action("Acciones", "Respawn (P)", respawn)
	_panel.add_toggle("Acciones", "Ver impactos", _impacts.visible, func(on: bool) -> void: _impacts.visible = on)
	# «Ser» cambia TU personaje y deja la P en ese arquetipo; «Spawnear» deja uno al lado, sin tocar la elección.
	_panel.add_text("Arquetipos", "P respawnea como: %s" % DebugArchetype.label())
	_panel.add_action("Arquetipos", "Ser: aleatorio", func() -> void: respawn_as(DebugArchetype.NONE))
	for a: int in EntityArchetype.Archetype.values():
		_panel.add_action("Arquetipos", "Ser: %s" % str(EntityArchetype.Archetype.keys()[a]),
			func() -> void: respawn_as(a))
	_panel.add_action("Arquetipos", "Spawnear: aleatorio", func() -> void: _spawn_character(DebugArchetype.free_seed()))
	for b: int in EntityArchetype.Archetype.values():
		_panel.add_action("Arquetipos", "Spawnear: %s" % str(EntityArchetype.Archetype.keys()[b]),
			func() -> void: _spawn_character(DebugArchetype.seed_for(b)))
	_panel.add_action("Spawn", "Go to start", _go_to_start)
	_panel.add_action("Spawn", "Character", func() -> void: _spawn_character(-1))
	_panel.add_action("Spawn", "Caja liviana ▪", func() -> void: _spawn("box_light_square"))
	_panel.add_action("Spawn", "Caja pesada ▪", func() -> void: _spawn("box_heavy_square"))
	_panel.add_action("Spawn", "Seat", func() -> void: _spawn("seat"))
	_panel.add_action("Spawn", "Limpiar spawns", func() -> void: NetSpawner.request_clear_all())


func _stats_text(inst: EntityInstantiation) -> String:
	var arch := inst.arch_final
	var sizes := SkeletonSizesUtil.create(inst)
	var blend := "arch      (no blend)"
	if inst.archetype_blend > 0.0:
		blend = "secondary %s (%.0f%%)" % [str(EntityArchetype.Archetype.keys()[inst.secondary_archetype_type]),
			inst.archetype_blend * 100.0]
	return "\n".join([
		"seed      %d" % inst.master_seed,
		"arch      %s" % str(EntityArchetype.Archetype.keys()[inst.archetype_type]),
		blend,
		"%s  |  age %d" % [EntitySpecie.Specie.keys()[inst.specie_type], inst.age],
		"",
		"height    %.2f m" % sizes.total_height,
		"weight    %.1f kg" % arch.weight,
		"speed     %.1f" % arch.speed,
		"strength  %.2f" % arch.strength,
		"jump      %.2fm" % arch.jump_height,
		"arm       %.2f m  (reach %.2f)  k %.2f" % [sizes.arm_reach, sizes.interaction_reach, arch.arms_length],
		"leg       %.2f m                k %.2f" % [sizes.leg_height, arch.legs_length],
		"fatness   %.2f" % arch.fatness,
		"muscle    %.2f" % arch.muscularity,
	])


func _net_text() -> String:
	if SessionManager.is_host and SessionManager.lobby_code != "":
		return "Host — código %s" % SessionManager.lobby_code
	if SessionManager.is_host:
		return "Host"
	if SessionManager.session_started and SessionManager.local_peer_id != 1:
		return "Cliente"
	return "Solo (local)"


func _go_to_start() -> void:
	var spawner := get_tree().get_first_node_in_group("character_spawner")
	if spawner and spawner.has_method("respawn_local_at_start"):
		spawner.respawn_local_at_start()


## Dos pasos delante de la mirada.
func _ahead() -> Vector3:
	var forward := -controller.player_camera.global_transform.basis.z
	return controller.char_rigidbody.global_position + forward * 2.5 + Vector3.UP


## UNO PARADO AL LADO, para mirar dos siluetas juntas. No pasa por NetSpawner: es una ayuda, no un objeto de la partida.
## Sin semilla, la del arquetipo elegido.
func _spawn_character(character_seed: int) -> void:
	var person := (load("res://game/character/player.tscn") as PackedScene).instantiate() as BoneInstantiator
	person.master_seed = character_seed if character_seed >= 0 else DebugArchetype.respawn_seed()
	get_tree().current_scene.add_child(person)
	person.global_position = _ahead()


## Una caja (cae sola) o una silla (apoyada en el piso).
func _spawn(type_name: String) -> void:
	var at := _ahead()
	if type_name == "seat":
		var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP, at + Vector3.DOWN * 20.0)
		query.exclude = [controller.char_rigidbody.get_rid()]
		var hit := controller.char_rigidbody.get_world_3d().direct_space_state.intersect_ray(query)
		if hit:
			at = hit.position
	NetSpawner.request_spawn(type_name, Transform3D(Basis(), at))
