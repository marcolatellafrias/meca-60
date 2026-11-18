class_name BaseAirlock
extends Node3D

## LA ESCLUSA, LA SALA DE ESPERA DE LA BASE (ver BaseLayout; el usuario, 17/11/2026: «una pequeña zona en la que todos
## los jugadores puedan estar juntos antes de comenzar la partida. Y después de pasar esa puerta… la compuerta esa se
## cierra para siempre»). Un cuadrado chico, del lado del fondo de la franja, en su punta:
##   · SE APARECE ACÁ. Dos bancos enfrentados, una luz roja que gira y el cartel «esperando tripulación». Mientras tanto,
##     la meca se arma del otro lado de la compuerta (con los que son): al abrirla no cambia a la vista.
##   · EL BOTÓN, al lado de la compuerta de adelante (un botón de compuerta de los tableros, ButtonArchetype; el usuario:
##     «un botoncito ahí de los de controllables»). Al apretarlo: la luz pasa a verde, un poco de vapor, la compuerta
##     se abre; a los OPEN_TIME se cierra y no se abre más (el botón ya no hace nada).
##   · LA COMPUERTA DE ATRÁS, la de «afuera», sellada en el juego. PARA PROBAR EN EL SANDBOX se abre con un botón de
##     afuera, así se puede entrar caminando; y la tecla de la parcela la rearma (ver BaseArchetype).
## En su marco: X hacia afuera de la franja (0 la compuerta de adelante), Z a lo largo de la punta de la franja, y = 0
## el piso.

## Lo que queda abierta la compuerta de adelante antes de cerrarse para siempre (s), y la de atrás al probar.
const OPEN_TIME := 6.0
const BACK_OPEN_TIME := 5.0
## El hueco de las compuertas.
const DOOR := Vector2(2.2, 2.6)
const WAITING := "ESPERANDO TRIPULACIÓN"
const GO := "ADELANTE"
const SEALED := "CERRADA"
const RED := Color(1.0, 0.18, 0.12)
const GREEN := Color(0.25, 1.0, 0.35)

## Si todavía se puede abrir (no se abrió nunca, o se rearmó).
var armed := true
var _side := 6.0
var _tall := 4.0
var _front: BaseSlideDoor
var _back: BaseSlideDoor
var _beacon: Node3D
var _lamp: SpotLight3D
var _glow: OmniLight3D
var _bulb: MeshInstance3D
var _sign: Label3D


## Arma la esclusa: un cuadrado de lado `side` y alto `tall`.
func build(side: float, tall: float) -> void:
	_side = side
	_tall = tall
	var walls := StaticBody3D.new()
	walls.name = "Paredes"
	PhysicsLayers.mark_fixed(walls)
	add_child(walls)
	var wall := BaseLayout.WALL
	var color := BaseLayout.WALL_COLOR
	Clay.solid(walls, Vector3(side, 0.4, side), Vector3(side * 0.5, -0.2, side * 0.5), BaseLayout.FLOOR_COLOR)
	Clay.solid(walls, Vector3(side + wall, BaseLayout.ROOF, side + wall), Vector3(side * 0.5, tall + BaseLayout.ROOF * 0.5,
		side * 0.5), color)
	for z: float in [0.0, side]:
		Clay.solid(walls, Vector3(side + wall, tall, wall), Vector3(side * 0.5, tall * 0.5, z), color)
	for x: float in [0.0, side]:
		_door_wall(walls, x)
	# los dos bancos, contra los costados
	for z: float in [0.55, side - 0.55]:
		Clay.solid(walls, Vector3(side - 1.6, 0.45, 0.5), Vector3(side * 0.5, 0.225, z), Color(0.55, 0.45, 0.33))
	_front = BaseSlideDoor.new()
	_front.name = "Adelante"
	_front.transform = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.0, 0.0, side * 0.5))
	add_child(_front)
	_front.build(DOOR.x, DOOR.y, wall)
	_back = BaseSlideDoor.new()
	_back.name = "Atrás"
	_back.transform = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(side, 0.0, side * 0.5))
	add_child(_back)
	_back.build(DOOR.x, DOOR.y, wall)
	_beacon_light()
	_sign = Label3D.new()
	_sign.font_size = 64
	_sign.pixel_size = 0.004
	_sign.outline_size = 10
	_sign.transform = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(wall * 0.5 + 0.02, DOOR.y + 0.45, side * 0.5))
	add_child(_sign)
	# el botón de adentro, al lado de la compuerta de adelante, mirando a la esclusa; el de afuera, al lado de la de
	# atrás, mirando afuera (sólo para probar)
	_button(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(wall * 0.5, 1.25, side * 0.5 + DOOR.x * 0.5 + 0.45)),
		_on_front_pressed)
	_button(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(side + wall * 0.5, 1.25, side * 0.5 - DOOR.x * 0.5 - 0.45)),
		_on_back_pressed)
	_show()


## Una pared con el hueco de la compuerta en el medio (en x).
func _door_wall(walls: StaticBody3D, x: float) -> void:
	var wall := BaseLayout.WALL
	var piece := (_side - DOOR.x) * 0.5
	for z: float in [piece * 0.5, _side - piece * 0.5]:
		Clay.solid(walls, Vector3(wall, _tall, piece), Vector3(x, _tall * 0.5, z), BaseLayout.WALL_COLOR)
	Clay.solid(walls, Vector3(wall, _tall - DOOR.y, DOOR.x), Vector3(x, (_tall + DOOR.y) * 0.5, _side * 0.5),
		BaseLayout.WALL_COLOR)


## LA LUZ QUE GIRA: una baliza en el techo con un foco que barre las paredes, y un brillo del mismo color.
func _beacon_light() -> void:
	_beacon = Node3D.new()
	_beacon.position = Vector3(_side * 0.5, _tall - 0.25, _side * 0.5)
	add_child(_beacon)
	_bulb = Clay.cylinder(_beacon, 0.16, 0.25, Vector3.ZERO, RED)
	# propio: el de Clay es compartido por color, y éste cambia
	_bulb.material_override = (_bulb.material_override as StandardMaterial3D).duplicate()
	_lamp = SpotLight3D.new()
	_lamp.basis = Basis(Vector3.RIGHT, deg_to_rad(-20.0))
	_lamp.spot_range = _side * 1.5
	_lamp.spot_angle = 25.0
	_lamp.light_energy = 6.0
	_beacon.add_child(_lamp)
	_glow = OmniLight3D.new()
	_glow.omni_range = _side
	_glow.light_energy = 0.8
	_beacon.add_child(_glow)


func _button(where: Transform3D, on_press: Callable) -> void:
	var mount := Node3D.new()
	mount.transform = where
	add_child(mount)
	var plate := ButtonArchetype.for_control(ControlArchetype.DOOR, GREEN)
	var cells := plate.half_cells()
	var area := Vector2(cells) * ProceduralDashboard.CELL * 0.5
	# la chapa donde va, y el botón centrado en ella (`mount_half` lo pone desde su esquina)
	Clay.box(mount, Vector3(area.x + 0.08, area.y + 0.08, 0.02), Vector3(0, 0, 0.01), Clay.DARK)
	var holder := Node3D.new()
	holder.position = Vector3(-area.x * 0.5, area.y * 0.5, 0.02)
	mount.add_child(holder)
	var root := plate.mount_half(0, holder, Vector2i.ZERO)
	var touch := ButtonArchetype.button_of(root)
	if touch != null:
		touch.pressed.connect(on_press)


func _process(delta: float) -> void:
	if is_instance_valid(_beacon):
		_beacon.rotate_y(delta * (3.0 if armed else 0.0))


## EL BOTÓN DE ADENTRO, EN RED (ver docs/technical/flujo-de-partida.md): lo aprieta el capitán, que es el host; el host
## la abre en todos (`_open`, para todos y para él). Si lo aprieta otro, se lo pide al host, que no le hace caso: abre
## sólo el capitán. Sin red (el sandbox), el host es uno mismo.
func _on_front_pressed() -> void:
	if not armed:
		return
	if multiplayer.is_server():
		_open.rpc()
	else:
		_request_open.rpc_id(1)


@rpc("any_peer", "reliable")
func _request_open() -> void:
	# abre sólo el capitán (el host, por ahora); un pedido de otro no hace nada
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == 1:
		_open.rpc()


@rpc("authority", "call_local", "reliable")
func _open() -> void:
	if not armed:
		return
	armed = false
	# abrir la esclusa EMPIEZA LA PARTIDA: desde acá no se une nadie más (ver SessionManager.close_to_new_players)
	if multiplayer.is_server():
		SessionManager.close_to_new_players()
	_show(GO, GREEN)
	_puff()
	_front.set_open(true)
	await get_tree().create_timer(OPEN_TIME).timeout
	if is_instance_valid(_front):
		_front.set_open(false)
		_show(SEALED, RED.darkened(0.5))


func _on_back_pressed() -> void:
	if _back.is_open:
		return
	_back.set_open(true)
	await get_tree().create_timer(BACK_OPEN_TIME).timeout
	if is_instance_valid(_back):
		_back.set_open(false)


## LA REARMA (la tecla de la parcela, para volver a probar): cerrada, roja y esperando.
func rearm() -> void:
	armed = true
	_front.set_open(false)
	_show()


func _show(text := WAITING, color := RED) -> void:
	_sign.text = text
	_sign.modulate = color
	_sign.outline_modulate = Color(0.08, 0.08, 0.08)
	(_bulb.material_override as StandardMaterial3D).albedo_color = color
	(_bulb.material_override as StandardMaterial3D).emission_enabled = true
	(_bulb.material_override as StandardMaterial3D).emission = color
	_lamp.light_color = color
	_glow.light_color = color
	_lamp.visible = armed


## UN POCO DE VAPOR al abrir: unas bolas blancas que crecen y se apagan, del piso de la compuerta.
func _puff() -> void:
	for i in 6:
		var cloud := Clay.sphere(self, 0.3, Vector3(0.6 + randf() * 0.8, 0.3 + randf() * 0.6,
			_side * 0.5 + (randf() - 0.5) * DOOR.x), Color(0.95, 0.95, 0.95))
		var material := (cloud.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		cloud.material_override = material
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.6
		var tween := cloud.create_tween().set_parallel(true)
		tween.tween_property(cloud, "scale", Vector3.ONE * 4.0, 1.6)
		tween.tween_property(material, "albedo_color:a", 0.0, 1.6)
		tween.chain().tween_callback(cloud.queue_free)
