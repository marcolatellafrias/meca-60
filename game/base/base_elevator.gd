class_name BaseElevator
extends Node3D

## EL ASCENSOR DE LA MECA (ver docs/technical/flujo-de-partida.md, paso 7): el cuadrado del elevador es una plataforma
## que sube, con la meca y la tripulación, por la compuerta del techo y el pozo hasta la segunda compuerta, que da a la
## arena. El usuario, 19/11/2026: «el sistema este de compuertas… es básicamente para ocultar cosas y poder cargar cosas
## sin que los jugadores le vean… cuando selecciono un contrato y aprieto el botón de empezar… ahí se comienza a cargar
## la arena arriba»; «tienen que estar todos en la zona del ascensor para comenzar… el botón también tiene que estar en
## la zona adentro del ascensor… cuando se arranca el ascensor se hace como una barrera… que no se puedan tirar».
##   · EL BOTÓN, en un pedestal en la esquina de la plataforma que da al gimnasio y la franja, mirando al centro. Con un
##     cartel que dice qué falta: el contrato, los que no están arriba, o que está listo.
##   · AL APRETARLO (el capitán, con contrato y todos arriba): sube la BARANDA del borde, se abre la compuerta del techo,
##     la plataforma sube por el pozo (la de arriba se abre mientras) y al llegar, a ras del piso de la arena, la baranda
##     baja. En red lo dispara el host en todos (BaseSync.launch); cada máquina lo anda con los mismos tiempos.
## Avisa `launching` al arrancar (la base del juego arma la arena arriba) y `arrived` al llegar.

signal launching()
signal arrived()

## La plataforma: un pelo más chica que la boca. LO QUE SE PISA VA A RAS DEL PISO (22/11/2026; el usuario: «diferencias de
## altura leves que hace que se trabe la meca»: eran 5 cm); sólo LO QUE SE VE sube `LIFT`, para tapar la pintura del pozo.
const MARGIN := 0.05
const THICK := 0.3
const LIFT := 0.035
## La baranda: lo que se ve, y lo que frena (más alto: que no se pueda saltar).
const RAIL_SEEN := 1.2
const RAIL_SOLID := 3.5
const RAIL_THICK := 0.15
const RAIL_TIME := 1.0
## A qué velocidad sube (m/s).
const SPEED := 2.5
const PEDESTAL := Vector3(0.5, 1.05, 0.5)
const PEDESTAL_INSET := 0.8
const SIGN_COLOR := Color(0.25, 1.0, 0.35)
const WAIT_COLOR := Color(1.0, 0.75, 0.2)

var launched := false
var _platform: AnimatableBody3D
var _rail: Node3D
var _rail_shapes: Array[CollisionShape3D] = []
var _sign: Label3D
var _half := 4.5
var _clock := 0.0


func build() -> void:
	var side := BaseLayout.span() - MARGIN * 2.0
	_half = side * 0.5
	_platform = AnimatableBody3D.new()
	_platform.name = "Plataforma"
	_platform.sync_to_physics = true
	PhysicsLayers.mark_fixed(_platform)
	_platform.position = BaseLayout.at(BaseLayout.ELEVATOR * 0.5, BaseLayout.NAVE * 0.5, 0.0)
	add_child(_platform)
	Clay.shape_box(_platform, Vector3(side, THICK, side), Vector3(0, -THICK * 0.5, 0))
	Clay.box(_platform, Vector3(side, THICK, side), Vector3(0, LIFT - THICK * 0.5, 0), BaseLayout.ELEVATOR_COLOR)
	_stripes(side)
	_build_rail(side)
	_pedestal()


## El borde amarillo, a rayas, como el que tenía pintado el piso.
func _stripes(side: float) -> void:
	var dash := 0.5
	var count := int(side / (dash * 2.0))
	for i in count:
		var along := -_half + dash * (i * 2.0 + 0.5)
		for edge: float in [-_half + 0.1, _half - 0.1]:
			Clay.box(_platform, Vector3(dash, 0.02, 0.15), Vector3(along, LIFT + 0.01, edge), BaseLayout.STRIPE_COLOR)
			Clay.box(_platform, Vector3(0.15, 0.02, dash), Vector3(edge, LIFT + 0.01, along), BaseLayout.STRIPE_COLOR)


## LA BARANDA: cuatro paredes bajas por el borde, guardadas abajo de la plataforma (no se ven ni frenan) hasta que sube.
func _build_rail(side: float) -> void:
	_rail = Node3D.new()
	_rail.name = "Baranda"
	_rail.position.y = -RAIL_SEEN - 0.1
	_platform.add_child(_rail)
	var edge := _half - RAIL_THICK * 0.5
	for i in 4:
		var along_x := i < 2
		var sign := -1.0 if i % 2 == 0 else 1.0
		var size := Vector3(side, RAIL_SEEN, RAIL_THICK) if along_x else Vector3(RAIL_THICK, RAIL_SEEN, side)
		var at := Vector3(0, LIFT + RAIL_SEEN * 0.5, sign * edge) if along_x else Vector3(sign * edge, LIFT + RAIL_SEEN * 0.5, 0)
		Clay.box(_rail, size, at, BaseLayout.HAZARD_DARK)
		var band := size
		band.y = 0.15
		Clay.box(_rail, band + Vector3(0.01, 0, 0.01), at + Vector3.UP * (RAIL_SEEN * 0.5 - 0.075), BaseLayout.STRIPE_COLOR)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(size.x, RAIL_SOLID, size.z)
		shape.shape = box
		shape.position = Vector3(at.x, LIFT + RAIL_SOLID * 0.5 - RAIL_SEEN - 0.1, at.z) - Vector3(0, _rail.position.y, 0) \
			+ Vector3(0, _rail.position.y, 0)
		shape.position.y = LIFT + RAIL_SOLID * 0.5
		shape.disabled = true
		# la parte que frena va en la plataforma (no baja con lo que se ve): se prende sólo con la baranda arriba
		_platform.add_child(shape)
		_rail_shapes.append(shape)


## EL PEDESTAL CON EL BOTÓN, en la esquina hacia el gimnasio y la franja, mirando al centro; arriba, el cartel.
func _pedestal() -> void:
	var corner := Vector3(_half - PEDESTAL_INSET, LIFT, _half - PEDESTAL_INSET)
	var facing := Basis(Vector3.UP, atan2(-1.0, -1.0))
	var stand := StaticBody3D.new()
	stand.name = "Pedestal"
	stand.transform = Transform3D(facing, corner)
	PhysicsLayers.mark_fixed(stand)
	_platform.add_child(stand)
	Clay.solid(stand, PEDESTAL, Vector3.UP * PEDESTAL.y * 0.5, BaseLayout.CONSOLE_COLOR)
	Clay.box(stand, Vector3(0.34, 0.24, 0.02), Vector3(0.0, PEDESTAL.y - 0.2, PEDESTAL.z * 0.5 + 0.01), SIGN_COLOR)
	# SE APUNTA EL PEDESTAL ENTERO (BaseLiftUse), como la puerta de la esclusa.
	var use := BaseLiftUse.new()
	use.elevator = self
	use.position = Vector3.UP * PEDESTAL.y * 0.6
	stand.add_child(use)
	_sign = Label3D.new()
	_sign.font_size = 64
	_sign.pixel_size = 0.008
	_sign.outline_size = 8
	# se lee de donde se lo mire (la tripulación llega de todos lados)
	_sign.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_sign.outline_modulate = Color(0.08, 0.08, 0.08)
	_sign.transform = Transform3D(facing, corner + Vector3.UP * (PEDESTAL.y + 0.45))
	_platform.add_child(_sign)


func _on_pressed() -> void:
	# en la partida, el host lo dispara en todos; en el sandbox, éste
	if BaseSync.current != null:
		BaseSync.current.launch()
	elif can_launch():
		launch()


## LOS QUE FALTAN SUBIR: los jugadores (los personajes de la red, `char_<peer>`, ver CharacterSpawner) que no están
## parados sobre la plataforma.
func missing() -> int:
	var out := 0
	for player: Node in get_tree().root.find_children("char_*", "BoneInstantiator", true, false):
		var body := (player as BoneInstantiator).char_rigidbody
		if not is_instance_valid(body):
			continue
		var here := _platform.to_local(body.global_position)
		if absf(here.x) > _half or absf(here.z) > _half or here.y < -1.0 or here.y > 4.0:
			out += 1
	return out


func can_launch() -> bool:
	return not launched and BaseState.current.contract >= 0 and missing() == 0


## ARRANCA: la baranda, la compuerta del techo, la subida (la de arriba se abre mientras) y la baranda que baja.
func launch() -> void:
	if launched:
		return
	launched = true
	launching.emit()
	_set_rail(true)
	var hatch := get_parent().get_node_or_null("Compuerta") as BaseHatch
	var top := get_parent().get_node_or_null("Compuerta de arriba") as BaseHatch
	if hatch:
		hatch.set_open(true)
	await get_tree().create_timer(BaseHatch.SLIDE_TIME + 0.3).timeout
	if top:
		top.set_open(true)
	var goal := _platform.position.y + BaseLayout.shaft_top()
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_platform, "position:y", goal, (goal - _platform.position.y) / SPEED)
	await tween.finished
	_set_rail(false)
	arrived.emit()


## La vuelve abajo, cerrada (la tecla de la parcela, para volver a probar).
func reset() -> void:
	launched = false
	_platform.position.y = BaseLayout.at(0, 0).y
	_set_rail(false)
	for name: String in ["Compuerta", "Compuerta de arriba"]:
		var hatch := get_parent().get_node_or_null(name) as BaseHatch
		if hatch:
			hatch.set_open(false)


func _set_rail(up: bool) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(_rail, "position:y", 0.0 if up else -RAIL_SEEN - 0.1, RAIL_TIME)
	for shape in _rail_shapes:
		shape.set_deferred("disabled", not up)


func _process(delta: float) -> void:
	_clock += delta
	if _clock < 0.25 or _sign == null:
		return
	_clock = 0.0
	var color := WAIT_COLOR
	var text := ""
	if launched:
		text = "ARENA"
		color = SIGN_COLOR
	elif BaseState.current.contract < 0:
		text = "FIRMÁ UN CONTRATO"
	else:
		var left := missing()
		if left > 0:
			text = "FALTA%s SUBIR %d" % ["N" if left > 1 else "", left]
		else:
			text = "LISTO" if BaseState.is_captain(get_tree()) else "LISTO: EL CAPITÁN APRIETA"
			color = SIGN_COLOR
	_sign.text = text
	_sign.modulate = color
