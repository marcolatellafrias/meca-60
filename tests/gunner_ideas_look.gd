extends Node

## EL PUESTO DEL ARTILLERO, MUCHAS IDEAS (18/11/2026; el usuario, de tests/artillery_board_look: «dos controles separados
## con hitboxes separadas que cuando los capturas hace lo mismo… muy mala práctica»; «la 3 lo soluciona… poniendo dos
## armas y haciendo que cada arma sea su interruptor… similar a los brazos desde el módulo de abajo»; «con ese sistema…
## no podemos hacer una caja de 6 misiles… que era como gran parte de la piel del artillero»; «la 2… tapa demasiado la
## visión»; «podés jugar… con distintas formas de poner la silla o la torre o sus paneles… 30 o 40… pensá bien… qué es lo
## que querés experimentar y por qué»). UNA meca jaula: cada idea se arma en el puesto del artillero, se le sacan dos
## fotos (de costado y desde sus ojos) y se borra. Las hojas, de ocho ideas: artillero_1.png a artillero_4.png.
##   tools/godot_ventana.sh res://tests/gunner_ideas_look.tscn -- --salida=C:/carpeta
##
## Todo en el espacio de la silla del artillero (m): −Z adelante, los ojos en `EYE`, las manos en L en `HAND`.

const VIEW := Vector2i(1280, 720)
const PER_SHEET := 8
## Cada idea: el número y su nombre, y qué prueba (lo que va en el epígrafe).
const IDEAS := [
	# A. UNA SOLA PIEZA PARA AGARRAR
	["1. horquilla: las dos manijas son una sola pieza, con el tablero entre ellas", "un solo mando con dos manos"],
	["2. la horquilla, con la caja de misiles pegada al costado de la ametralladora", "un mando, dos armas: un botón elige"],
	["3. manubrio: una barra con el tablero en el medio, las armas debajo", "un mando ancho y bajo, se ve por arriba"],
	["4. una palanca sola entre las rodillas; los botones en los apoyabrazos", "una mano apunta, la otra elige"],
	["5. la silla es el arma: las armas a los costados de la silla, manijas en los apoyabrazos", "girar la silla es apuntar"],
	["6. un yugo que cuelga de un arco sobre la cabeza", "nada adelante de la vista hasta agarrarlo"],
	# B. CADA ARMA SU MANDO (como los brazos de abajo)
	["7. ametralladora a la derecha con su manija; misiles a la izquierda con la suya", "dos armas, dos mandos distintos"],
	["8. ametralladora adelante; los misiles en un mástil atrás, con una palanca al costado", "apuntar y lanzar son cosas distintas"],
	["9. dos brazos articulados desde los hombros de la torre, cada uno con su arma", "lo mismo que abajo, en chico"],
	["10. la ametralladora en un pivote a la derecha; un lanzacohetes de hombro a la izquierda", "un arma fija y una que se lleva"],
	# C. LOS MISILES, A LA VISTA
	["11. la caja de 6 en la espalda de la meca, detrás de la silla: salen por arriba de la cabeza", "verlos salir"],
	["12. la caja de 6 en el frente de la torre, debajo de la vista", "misiles siempre a la vista, sin tapar"],
	["13. dos cajas de 3 a los costados de la silla, giran con ella", "los misiles como hombreras de la silla"],
	["14. la caja de 6 sube desde adentro de la torre cuando se la elige", "lo que no se usa no está"],
	["15. seis cohetes en tambor alrededor del caño de la ametralladora", "un arma, dos disparos, gira"],
	["16. una fila de cohetes colgando debajo del plato", "abajo, fuera de la vista"],
	# D. DÓNDE SE SIENTA
	["17. cúpula: hundido en la torre hasta el pecho, el tablero en el aro de la cúpula", "protegido, el tablero rodea"],
	["18. la torre más baja: la silla al ras del bloque, el arma arriba de la torre adelante", "el arma lejos de la cara"],
	["19. de espaldas: el artillero mira para atrás", "cubre lo que los otros no ven"],
	["20. una bola de vidrio al costado de la torre, con la silla adentro", "la bola gira entera"],
	["21. parado en un aro, sin silla; las armas cuelgan del aro", "se mueve más, se baja rápido"],
	["22. la silla en una grúa alta sobre la torre", "ver más lejos que nadie"],
	["23. un balcón al costado derecho de la meca", "el artillero fuera del medio"],
	# E. DÓNDE VA EL TABLERO
	["24. un anillo a la cintura con paneles; el arma corre por el anillo", "el riel y el tablero son lo mismo"],
	["25. el tablero en el piso, entre los pies", "mirar abajo para ver el estado"],
	["26. el tablero arriba, en un arco sobre la cabeza", "mirar arriba para ver el estado"],
	["27. una pantalla grande sobre la ametralladora, que es también la mira", "la mira muestra todo"],
	["28. tres pantallas en brazos articulados alrededor de la silla", "pantallas que se acomodan"],
	# F. MÁS DE JUEGO
	["29. carrusel: tres armas en un tambor detrás de la silla; elegir trae una al frente", "una a la vez, cambiar se ve"],
	["30. la ametralladora se pliega contra la torre al soltarla", "suelta no tapa nada"],
	["31. mira de reflejo: un vidrio fino con la cruz, el tablero abajo en la culata", "apuntar sin tapar"],
	["32. la caja de misiles es el respaldo de la silla: dispara para atrás y gira", "el artillero sentado en sus misiles"],
]
const HIP := 0.5
const SHOULDER := 1.0
const EYE := Vector3(0.0, 1.15, 0.02)
const HAND := Vector3(0.17, 0.64, -0.33)
const GUNMETAL := Color(0.24, 0.25, 0.27)
const PLATE := Color(0.5, 0.52, 0.55)
## Lo que se agarra (un mando entero), de un color: así se ve que es una sola pieza.
const GRAB := Color(0.62, 0.22, 0.18)
const SCREEN := Color(0.05, 0.12, 0.06)
const GREEN := Color(0.35, 0.9, 0.4)
const RED := Color(0.85, 0.2, 0.15)
const AMMO := [Color(0.85, 0.75, 0.3), Color(0.3, 0.6, 0.9), Color(0.85, 0.35, 0.25)]
const GLASS := Color(0.62, 0.8, 0.92, 0.3)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
var _note: Label = null
var _shots: Array = []
var _mech: CageMech = null
var _cage: CageCabin = null
var _chair: Node3D = null
## Lo de la idea de ahora (se borra al pasar a la siguiente); dónde quedan los ojos y las manos del maniquí.
var _rig: Node3D = null
var _eyes := EYE
var _hands: Array[Vector3] = []
var _sunk := 0.0
var _standing := false
var _facing := 0.0


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	for k in 5:
		Clay.box(ground, Vector3(2.0, 3.0 + k, 2.0), Vector3(-12.0 + k * 6.0, 1.5 + k * 0.5, -40.0), Color(0.6, 0.35, 0.3))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 205.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.8, 0.82, 0.85)
	world.environment.ambient_light_energy = 0.6
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	_eye.near = 0.02
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = _label(layer, Vector2(20, 8), 40)
	_note = _label(layer, Vector2(20, 110), 32)
	_mech = CageMech.new()
	_mech.scripted = true
	_mech.position = Vector3(0.0, Mech.standing_height(Mech.Cabin.CAGE), 0.0)
	add_child(_mech)
	await get_tree().create_timer(2.0).timeout
	for found in get_tree().root.find_children("*", "Label3D", true, false):
		(found as Label3D).visible = false
	_cage = _mech.cabin as CageCabin
	_chair = _cage.chairs[CageCabin.GUNNER] as Node3D
	_cage.gun.visible = false
	var turn := _cage.gun.get_parent() as Node3D
	for child in turn.get_children():
		if child != _cage.gun and child is MeshInstance3D and (child as Node3D).position.y > 0.3:
			(child as Node3D).visible = false
	for index in IDEAS.size():
		# Lo de la idea va al lado de la silla (en su lugar), no adentro: así la silla se puede esconder sola.
		_rig = Node3D.new()
		_chair.get_parent().add_child(_rig)
		_rig.transform = _chair.transform
		_eyes = EYE
		_hands = [Vector3(-HAND.x, HAND.y, HAND.z), HAND]
		_sunk = 0.0
		_standing = false
		_facing = 0.0
		_chair.visible = true
		_idea(index + 1)
		# Hundido: la silla de verdad queda arriba; una de maqueta, abajo.
		if _sunk > 0.0:
			_chair.visible = false
			_seat(Vector3(0.0, -_sunk, 0.0))
		_dummy()
		await get_tree().process_frame
		var seat := _rig.global_transform
		var at := seat * Vector3(0.0, 0.75 - _sunk, -0.4)
		await _shot(IDEAS[index][0], "prueba: " + IDEAS[index][1], at + seat.basis * Vector3(2.4, 0.5, -0.9), at, 55.0)
		var eye := seat * (_eyes - Vector3(0.0, _sunk, 0.0))
		await _shot(String(IDEAS[index][0]).get_slice(".", 0) + ". desde sus ojos", "", eye,
			eye + seat.basis * Vector3(0.0, -1.2, -3.0), 85.0)
		_rig.queue_free()
		await get_tree().process_frame
		if (index + 1) % PER_SHEET == 0 or index == IDEAS.size() - 1:
			_save(index / PER_SHEET + 1)
	get_tree().quit()


## ── LAS IDEAS ────────────────────────────────────────────────────────────────────────────────────────────────────

func _idea(number: int) -> void:
	var r := _rig
	match number:
		1:
			_post(Vector3(0.0, 0.0, -0.5), 0.55)
			_mg(Vector3(0.0, 0.58, -0.5))
			_spade(Vector3(0.0, 0.64, -0.36), 0.2, true)
		2:
			_post(Vector3(0.0, 0.0, -0.5), 0.55)
			_mg(Vector3(0.07, 0.58, -0.5))
			_missiles(Vector3(-0.16, 0.6, -0.55), 3, 2, 0.07)
			_spade(Vector3(0.0, 0.64, -0.36), 0.22, true)
		3:
			_post(Vector3(0.0, 0.0, -0.55), 0.45)
			_mg(Vector3(0.12, 0.5, -0.5))
			_missiles(Vector3(-0.14, 0.5, -0.55), 3, 2, 0.06)
			_bar(Vector3(0.0, 0.66, -0.36), 0.24)
			_board(Vector3(0.0, 0.7, -0.38), Vector2(0.22, 0.12), -60.0)
		4:
			_stick(Vector3(0.0, 0.0, -0.3))
			_hands = [Vector3(-0.24, 0.55, -0.12), Vector3(0.0, 0.62, -0.3)]
			_board(Vector3(-0.27, 0.5, -0.1), Vector2(0.12, 0.3), -90.0, 0.0)
			_board(Vector3(0.27, 0.5, -0.1), Vector2(0.12, 0.3), -90.0, 0.0)
			_post(Vector3(0.0, 0.0, -0.75), 0.45)
			_mg(Vector3(0.1, 0.5, -0.75))
			_missiles(Vector3(-0.14, 0.52, -0.8), 3, 2, 0.06)
		5:
			_mg(Vector3(0.36, 0.55, -0.1))
			_missiles(Vector3(-0.38, 0.62, -0.1), 3, 2, 0.07)
			for s: float in [-1.0, 1.0]:
				Clay.box(r, Vector3(0.08, 0.06, 0.4), Vector3(s * 0.27, 0.48, -0.05), GRAB)
				Clay.cylinder(r, 0.025, 0.12, Vector3(s * 0.27, 0.56, -0.22), GRAB)
			_board(Vector3(0.27, 0.52, 0.1), Vector2(0.08, 0.14), -90.0)
			_hands = [Vector3(-0.27, 0.6, -0.22), Vector3(0.27, 0.6, -0.22)]
		6:
			_arch(0.62)
			Clay.cylinder(r, 0.02, 0.35, Vector3(0.0, 1.45, -0.42), GUNMETAL)
			_spade(Vector3(0.0, 1.22, -0.42), 0.16, false)
			_post(Vector3(0.0, 0.0, -0.7), 0.5)
			_mg(Vector3(0.0, 0.55, -0.7))
			_hands = [Vector3(-0.16, 1.22, -0.42), Vector3(0.16, 1.22, -0.42)]
		7:
			_post(Vector3(0.3, 0.0, -0.45), 0.5)
			_mg(Vector3(0.3, 0.6, -0.42))
			_grip(Vector3(0.3, 0.6, -0.3))
			_post(Vector3(-0.32, 0.0, -0.45), 0.5)
			_missiles(Vector3(-0.32, 0.66, -0.5), 3, 2, 0.07)
			_grip(Vector3(-0.32, 0.6, -0.3))
			_hands = [Vector3(-0.32, 0.6, -0.3), Vector3(0.3, 0.6, -0.3)]
			_board(Vector3(0.0, 0.42, -0.42), Vector2(0.3, 0.16), -30.0)
		8:
			_post(Vector3(0.0, 0.0, -0.5), 0.55)
			_mg(Vector3(0.0, 0.58, -0.5))
			_grip(Vector3(0.0, 0.6, -0.33))
			Clay.box(r, Vector3(0.08, 1.6, 0.08), Vector3(0.0, 0.8, 0.45), GUNMETAL)
			_missiles(Vector3(0.0, 1.75, 0.45), 3, 2, 0.08, 20.0)
			_lever(Vector3(-0.3, 0.3, -0.15))
			_hands = [Vector3(-0.3, 0.62, -0.15), Vector3(0.0, 0.6, -0.33)]
		9:
			for s: float in [-1.0, 1.0]:
				var shoulder := Vector3(s * 0.45, 0.85, -0.05)
				var elbow := Vector3(s * 0.5, 0.6, -0.3)
				var wrist := Vector3(s * 0.3, 0.62, -0.5)
				_beam(shoulder, elbow, 0.05)
				_beam(elbow, wrist, 0.045)
				Clay.sphere(r, 0.07, shoulder, GUNMETAL)
				if s > 0.0:
					_mg(wrist + Vector3(0.0, -0.02, 0.05))
				else:
					_missiles(wrist, 3, 2, 0.06)
				_grip(Vector3(s * 0.3, 0.6, -0.33))
			_hands = [Vector3(-0.3, 0.6, -0.33), Vector3(0.3, 0.6, -0.33)]
		10:
			_post(Vector3(0.3, 0.0, -0.45), 0.5)
			_mg(Vector3(0.3, 0.6, -0.42))
			_grip(Vector3(0.3, 0.6, -0.3))
			# El lanzacohetes de hombro: un tubo largo apoyado en el hombro izquierdo.
			Clay.cylinder(r, 0.07, 1.1, Vector3(-0.2, 1.02, -0.15), CageCabin.YELLOW.darkened(0.2), Vector3(90.0, 0.0, 0.0))
			Clay.cylinder(r, 0.05, 0.02, Vector3(-0.2, 1.02, -0.71), CageCabin.HOLE, Vector3(90.0, 0.0, 0.0))
			Clay.box(r, Vector3(0.12, 0.12, 0.25), Vector3(0.0, 0.0, 0.35) + Vector3(-0.45, 0.6, 0.0), AMMO[2])
			_hands = [Vector3(-0.2, 0.95, -0.35), Vector3(0.3, 0.6, -0.3)]
		11:
			_post(Vector3(0.0, 0.0, -0.5), 0.55)
			_mg(Vector3(0.0, 0.58, -0.5))
			_spade(Vector3(0.0, 0.64, -0.36), 0.2, false)
			_missiles(Vector3(0.0, 1.35, 0.7), 3, 2, 0.1, 60.0)
			Clay.box(r, Vector3(0.5, 1.1, 0.12), Vector3(0.0, 0.7, 0.62), PLATE)
		12:
			_post(Vector3(0.0, 0.0, -0.45), 0.55)
			_mg(Vector3(0.0, 0.58, -0.45))
			_spade(Vector3(0.0, 0.64, -0.33), 0.2, false)
			_missiles(Vector3(0.0, 0.18, -0.85), 3, 2, 0.1)
		13:
			_post(Vector3(0.0, 0.0, -0.5), 0.55)
			_mg(Vector3(0.0, 0.58, -0.5))
			_spade(Vector3(0.0, 0.64, -0.36), 0.2, false)
			for s: float in [-1.0, 1.0]:
				Clay.box(r, Vector3(0.06, 0.4, 0.06), Vector3(s * 0.34, 0.6, 0.05), GUNMETAL)
				_missiles(Vector3(s * 0.38, 0.95, 0.0), 1, 3, 0.07)
		14:
			_post(Vector3(0.0, 0.0, -0.5), 0.55)
			_mg(Vector3(0.0, 0.58, -0.5))
			_spade(Vector3(0.0, 0.64, -0.36), 0.2, false)
			# La compuerta abierta en el plato y la caja subiendo, a medias.
			Clay.box(r, Vector3(0.5, 0.02, 0.35), Vector3(0.45, 0.02, -0.3), CageCabin.HOLE)
			Clay.box(r, Vector3(0.04, 0.6, 0.04), Vector3(0.45, 0.3, -0.3), GUNMETAL)
			_missiles(Vector3(0.45, 0.7, -0.35), 3, 2, 0.07)
		15:
			_post(Vector3(0.0, 0.0, -0.5), 0.55)
			_mg(Vector3(0.0, 0.58, -0.5))
			_spade(Vector3(0.0, 0.64, -0.36), 0.2, false)
			for k in 6:
				var angle := TAU * k / 6.0
				var spot := Vector3(cos(angle), sin(angle), 0.0) * 0.12 + Vector3(0.0, 0.59, -0.95)
				Clay.cylinder(r, 0.03, 0.4, spot, CageCabin.YELLOW.darkened(0.2), Vector3(90.0, 0.0, 0.0))
		16:
			_post(Vector3(0.0, 0.0, -0.5), 0.55)
			_mg(Vector3(0.0, 0.58, -0.5))
			_spade(Vector3(0.0, 0.64, -0.36), 0.2, false)
			for k in 5:
				var spot := Vector3(-0.3 + k * 0.15, -0.12, -0.5)
				Clay.cylinder(r, 0.04, 0.6, spot, CageCabin.YELLOW.darkened(0.2), Vector3(90.0, 0.0, 0.0))
				Clay.cylinder(r, 0.03, 0.02, spot + Vector3(0.0, 0.0, -0.31), CageCabin.HOLE, Vector3(90.0, 0.0, 0.0))
		17:
			# Hundido: la tapa de la torre le queda al pecho; el aro y el arma, a esa altura.
			_sunk = 0.55
			_ring(Vector3(0.0, 0.1, 0.0), 0.62, true)
			_mg(Vector3(0.0, 0.06, -0.62))
			_spade(Vector3(0.0, 0.12, -0.47), 0.2, false)
		18:
			# La silla más baja; el arma adelante, sobre el frente de la torre, debajo de la vista.
			_sunk = 0.55
			_post(Vector3(0.0, 0.0, -0.85), 0.3)
			_mg(Vector3(0.0, 0.32, -0.85))
			_spade(Vector3(0.0, 0.12, -0.42), 0.2, false)
			_beam(Vector3(0.0, 0.08, -0.42), Vector3(0.0, 0.3, -0.75), 0.02)
		19:
			_facing = PI
			_chair.visible = false
			_seat(Vector3.ZERO)
			_post(Vector3(0.0, 0.0, -0.5), 0.55)
			_mg(Vector3(0.0, 0.58, -0.5))
			_spade(Vector3(0.0, 0.64, -0.36), 0.2, true)
		20:
			_ball(Vector3(0.0, 0.7, -0.1), 0.95)
			_mg(Vector3(0.25, 0.4, -0.85))
			_mg(Vector3(-0.25, 0.4, -0.85))
			_spade(Vector3(0.0, 0.64, -0.36), 0.2, true)
		21:
			_standing = true
			_chair.visible = false
			_eyes = Vector3(0.0, 1.62, 0.02)
			_ring(Vector3(0.0, 1.0, 0.0), 0.5, false)
			_mg(Vector3(0.0, 1.02, -0.55))
			_spade(Vector3(0.0, 1.06, -0.42), 0.2, false)
			_hands = [Vector3(-0.2, 1.06, -0.42), Vector3(0.2, 1.06, -0.42)]
		22:
			_sunk = -1.2
			_chair.visible = false
			_seat(Vector3(0.0, 1.2, 0.0))
			Clay.box(r, Vector3(0.12, 1.5, 0.12), Vector3(0.0, -0.75 + 1.2, 0.5), GUNMETAL)
			Clay.box(r, Vector3(0.7, 0.06, 0.7), Vector3(0.0, 1.2 - 0.03, 0.0), PLATE)
			_post(Vector3(0.0, 1.2, -0.5), 0.55)
			_mg(Vector3(0.0, 1.78, -0.5))
			_spade(Vector3(0.0, 1.84, -0.36), 0.2, false)
		23:
			_post(Vector3(0.0, 0.0, -0.5), 0.55)
			_mg(Vector3(0.0, 0.58, -0.5))
			_spade(Vector3(0.0, 0.64, -0.36), 0.2, true)
			Clay.box(r, Vector3(1.4, 0.06, 1.2), Vector3(0.0, -0.03, -0.2), PLATE)
			for s: float in [-1.0, 1.0]:
				Clay.box(r, Vector3(0.04, 0.5, 1.2), Vector3(s * 0.7, 0.25, -0.2), GUNMETAL)
		24:
			_ring(Vector3(0.0, 0.62, 0.0), 0.62, true)
			_mg(Vector3(0.0, 0.66, -0.66))
			_spade(Vector3(0.0, 0.72, -0.52), 0.18, false)
			_hands = [Vector3(-0.18, 0.72, -0.52), Vector3(0.18, 0.72, -0.52)]
		25:
			_post(Vector3(0.0, 0.0, -0.5), 0.55)
			_mg(Vector3(0.0, 0.58, -0.5))
			_spade(Vector3(0.0, 0.64, -0.36), 0.2, false)
			_board(Vector3(0.0, 0.03, -0.45), Vector2(0.5, 0.3), -85.0)
		26:
			_arch(0.62)
			_board(Vector3(0.0, 1.5, -0.3), Vector2(0.6, 0.3), 70.0)
			_post(Vector3(0.0, 0.0, -0.5), 0.55)
			_mg(Vector3(0.0, 0.58, -0.5))
			_spade(Vector3(0.0, 0.64, -0.36), 0.2, false)
		27:
			_post(Vector3(0.0, 0.0, -0.55), 0.55)
			_mg(Vector3(0.0, 0.58, -0.55))
			_spade(Vector3(0.0, 0.64, -0.36), 0.2, false)
			Clay.box(r, Vector3(0.04, 0.2, 0.04), Vector3(0.0, 0.75, -0.55), GUNMETAL)
			_board(Vector3(0.0, 0.95, -0.55), Vector2(0.3, 0.2), 0.0)
		28:
			_post(Vector3(0.0, 0.0, -0.5), 0.55)
			_mg(Vector3(0.0, 0.58, -0.5))
			_spade(Vector3(0.0, 0.64, -0.36), 0.2, false)
			for spot: Vector3 in [Vector3(-0.55, 0.95, -0.3), Vector3(0.55, 0.95, -0.3), Vector3(-0.6, 0.6, 0.2)]:
				_screen_arm(Vector3(signf(spot.x) * 0.45, 0.0, 0.3), spot)
		29:
			_post(Vector3(0.0, 0.0, -0.5), 0.55)
			_mg(Vector3(0.0, 0.58, -0.5))
			_spade(Vector3(0.0, 0.64, -0.36), 0.2, false)
			Clay.cylinder(r, 0.45, 0.06, Vector3(0.0, 0.9, 0.62), GUNMETAL, Vector3(0.0, 0.0, 90.0))
			_missiles(Vector3(-0.0, 1.32, 0.62), 3, 2, 0.06)
			_cannon(Vector3(0.0, 0.62, 0.95))
		30:
			_post(Vector3(0.45, 0.0, -0.2), 0.5)
			# Plegada: la ametralladora parada contra el costado, los caños para arriba.
			var folded := Node3D.new()
			folded.position = Vector3(0.45, 0.55, -0.2)
			folded.rotation_degrees = Vector3(80.0, 0.0, 0.0)
			r.add_child(folded)
			_mg_on(folded, Vector3.ZERO)
			_spade_on(folded, Vector3(0.0, 0.06, 0.14), 0.16, false)
			_hands = [Vector3(-0.2, 0.55, -0.15), Vector3(0.2, 0.55, -0.15)]
		31:
			_post(Vector3(0.0, 0.0, -0.5), 0.55)
			_mg(Vector3(0.0, 0.58, -0.5))
			_spade(Vector3(0.0, 0.64, -0.36), 0.2, false)
			_board(Vector3(0.0, 0.7, -0.4), Vector2(0.24, 0.1), -70.0)
			var glass := Clay.box(r, Vector3(0.22, 0.16, 0.01), Vector3(0.0, 1.05, -0.55), GLASS)
			glass.material_override = _glass()
			Clay.box(r, Vector3(0.06, 0.004, 0.012), Vector3(0.0, 1.05, -0.55), RED)
			Clay.box(r, Vector3(0.004, 0.06, 0.012), Vector3(0.0, 1.05, -0.55), RED)
			Clay.box(r, Vector3(0.02, 0.35, 0.02), Vector3(0.0, 0.8, -0.55), GUNMETAL)
		32:
			_post(Vector3(0.0, 0.0, -0.5), 0.55)
			_mg(Vector3(0.0, 0.58, -0.5))
			_spade(Vector3(0.0, 0.64, -0.36), 0.2, false)
			var back := Node3D.new()
			back.position = Vector3(0.0, 0.9, 0.3)
			back.rotation_degrees = Vector3(0.0, 180.0, 0.0)
			r.add_child(back)
			_missiles_on(back, Vector3.ZERO, 3, 2, 0.11)


## ── LAS PIEZAS ───────────────────────────────────────────────────────────────────────────────────────────────────

## UNA SILLA DE MAQUETA (donde la de verdad no va): el asiento y el respaldo, en `at`.
func _seat(at: Vector3) -> void:
	Clay.box(_rig, Vector3(0.48, 0.08, 0.46), at + Vector3(0.0, 0.42, 0.02), Color(0.42, 0.36, 0.42))
	Clay.box(_rig, Vector3(0.48, 0.6, 0.08), at + Vector3(0.0, 0.72, 0.24), Color(0.42, 0.36, 0.42))
	Clay.cylinder(_rig, 0.05, 0.4, at + Vector3(0.0, 0.2, 0.05), GUNMETAL)


## Un pie del plato hasta `tall` de alto, en `at`.
func _post(at: Vector3, tall: float) -> void:
	Clay.cylinder(_rig, 0.035, tall, at + Vector3(0.0, tall * 0.5, 0.0), GUNMETAL)


func _mg(at: Vector3) -> void:
	_mg_on(_rig, at)


## LA AMETRALLADORA FINA: cajón, dos caños con aletas, la caja de munición al costado.
func _mg_on(parent: Node3D, at: Vector3) -> void:
	Clay.box(parent, Vector3(0.09, 0.09, 0.42), at + Vector3(0.0, 0.0, -0.12), GUNMETAL)
	for x: float in [-0.022, 0.022]:
		Clay.cylinder(parent, 0.017, 0.75, at + Vector3(x, 0.01, -0.68), CageCabin.RIM_COLOR, Vector3(90.0, 0.0, 0.0))
	for k in 4:
		Clay.cylinder(parent, 0.042, 0.015, at + Vector3(0.0, 0.01, -0.4 - k * 0.05), CageCabin.METAL, Vector3(90.0, 0.0, 0.0))
	Clay.box(parent, Vector3(0.08, 0.1, 0.14), at + Vector3(0.09, -0.02, -0.1), CageCabin.YELLOW.darkened(0.25))


func _missiles(at: Vector3, columns: int, rows: int, cell: float, pitch := 0.0) -> void:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation_degrees = Vector3(pitch, 0.0, 0.0)
	_rig.add_child(holder)
	_missiles_on(holder, Vector3.ZERO, columns, rows, cell)


## LA CAJA DE MISILES: `columns` × `rows` tubos de `cell`, con las bocas oscuras adelante (−Z) y la tapa amarilla.
func _missiles_on(parent: Node3D, at: Vector3, columns: int, rows: int, cell: float) -> void:
	var size := Vector3(columns * cell + 0.03, rows * cell + 0.03, cell * 5.0)
	Clay.box(parent, size, at, CageCabin.METAL)
	for c in columns:
		for k in rows:
			var spot := at + Vector3((c - (columns - 1) * 0.5) * cell, (k - (rows - 1) * 0.5) * cell, -size.z * 0.5 - 0.005)
			Clay.cylinder(parent, cell * 0.36, 0.012, spot, CageCabin.HOLE, Vector3(90.0, 0.0, 0.0))
			Clay.cylinder(parent, cell * 0.2, 0.014, spot, AMMO[2], Vector3(90.0, 0.0, 0.0))
	Clay.box(parent, Vector3(size.x + 0.01, 0.02, size.z * 0.6), at + Vector3(0.0, size.y * 0.5 + 0.01, 0.0), CageCabin.YELLOW)


## EL CAÑÓN CORTO: caño grueso y corto con su recámara.
func _cannon(at: Vector3) -> void:
	Clay.box(_rig, Vector3(0.12, 0.12, 0.3), at + Vector3(0.0, 0.0, -0.08), GUNMETAL)
	Clay.cylinder(_rig, 0.05, 0.42, at + Vector3(0.0, 0.0, -0.43), CageCabin.RIM_COLOR, Vector3(90.0, 0.0, 0.0))


func _spade(at: Vector3, half: float, with_board: bool) -> void:
	_spade_on(_rig, at, half, with_board)
	_hands = [at + Vector3(-half, 0.0, 0.0), at + Vector3(half, 0.0, 0.0)]


## LA HORQUILLA: dos manijas paradas unidas por una barra, TODO UNA PIEZA (del color de lo que se agarra); con
## `with_board`, el tablero entre las manijas, mirando al artillero.
func _spade_on(parent: Node3D, at: Vector3, half: float, with_board: bool) -> void:
	Clay.box(parent, Vector3(half * 2.0 + 0.05, 0.04, 0.04), at + Vector3(0.0, -0.08, 0.0), GRAB)
	for s: float in [-1.0, 1.0]:
		Clay.cylinder(parent, 0.024, 0.16, at + Vector3(s * half, 0.0, 0.0), GRAB)
		Clay.box(parent, Vector3(0.03, 0.03, 0.12), at + Vector3(s * half, -0.08, -0.06), GRAB)
	if with_board:
		var holder := Node3D.new()
		holder.position = at + Vector3(0.0, 0.04, -0.02)
		holder.rotation_degrees = Vector3(-20.0, 0.0, 0.0)
		parent.add_child(holder)
		var size := Vector2(half * 1.6, 0.16)
		Clay.box(holder, Vector3(size.x, size.y, 0.02), Vector3.ZERO, PLATE)
		_controls(holder, size)


## UNA MANIJA SUELTA (el mando de un arma), en `at`.
func _grip(at: Vector3) -> void:
	Clay.cylinder(_rig, 0.024, 0.16, at, GRAB)
	Clay.box(_rig, Vector3(0.03, 0.03, 0.12), at + Vector3(0.0, -0.08, -0.06), GRAB)


## UN MANUBRIO: una barra entera de lado a lado, de `half` a cada lado.
func _bar(at: Vector3, half: float) -> void:
	Clay.cylinder(_rig, 0.022, half * 2.0, at, GRAB, Vector3(0.0, 0.0, 90.0))
	for s: float in [-1.0, 1.0]:
		Clay.cylinder(_rig, 0.028, 0.12, at + Vector3(s * half, 0.0, 0.0), GRAB, Vector3(0.0, 0.0, 90.0))
	Clay.box(_rig, Vector3(0.04, 0.2, 0.04), at + Vector3(0.0, -0.1, -0.05), GUNMETAL)
	_hands = [at + Vector3(-half, 0.0, 0.0), at + Vector3(half, 0.0, 0.0)]


## UNA PALANCA SOLA, parada desde el piso en `at`.
func _stick(at: Vector3) -> void:
	Clay.box(_rig, Vector3(0.14, 0.04, 0.14), at, GUNMETAL)
	Clay.cylinder(_rig, 0.02, 0.6, at + Vector3(0.0, 0.3, 0.0), GRAB)
	Clay.sphere(_rig, 0.04, at + Vector3(0.0, 0.62, 0.0), GRAB)


## UNA PALANCA DE LANZAR al costado, en `at`.
func _lever(at: Vector3) -> void:
	Clay.box(_rig, Vector3(0.1, 0.3, 0.12), at, GUNMETAL)
	Clay.cylinder(_rig, 0.018, 0.3, at + Vector3(0.0, 0.3, 0.0), GRAB)
	Clay.sphere(_rig, 0.035, at + Vector3(0.0, 0.46, 0.0), RED)


## UN ARCO sobre la cabeza, de `half` a cada lado.
func _arch(half: float) -> void:
	for s: float in [-1.0, 1.0]:
		Clay.box(_rig, Vector3(0.05, 1.55, 0.05), Vector3(s * half, 0.78, -0.3), GUNMETAL)
	Clay.box(_rig, Vector3(half * 2.0 + 0.05, 0.05, 0.05), Vector3(0.0, 1.6, -0.3), GUNMETAL)


## UN ANILLO horizontal alrededor de la silla, a `at`, de `radius`; con `panels`, paneles colgados adelante.
func _ring(at: Vector3, radius: float, panels: bool) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.03
	torus.outer_radius = radius + 0.03
	ring.mesh = torus
	ring.position = at
	ring.material_override = _paint(GUNMETAL)
	_rig.add_child(ring)
	for k in 4:
		var angle := TAU * (k + 0.5) / 4.0
		var foot := Vector3(cos(angle), 0.0, sin(angle)) * radius
		Clay.box(_rig, Vector3(0.04, at.y, 0.04), Vector3(foot.x, at.y * 0.5, foot.z), GUNMETAL)
	if not panels:
		return
	for k in 3:
		var angle := deg_to_rad(-90.0 + (k - 1) * 40.0)
		var spot := Vector3(cos(angle), 0.0, sin(angle)) * (radius + 0.02) + Vector3(0.0, at.y + 0.1, 0.0)
		var holder := Node3D.new()
		holder.position = spot
		holder.rotation = Vector3(deg_to_rad(-55.0), -angle - PI * 0.5, 0.0)
		_rig.add_child(holder)
		Clay.box(holder, Vector3(0.3, 0.18, 0.02), Vector3.ZERO, PLATE)
		_controls(holder, Vector2(0.3, 0.18))


## UNA BOLA DE VIDRIO de `radius` alrededor de la silla, en `at`.
func _ball(at: Vector3, radius: float) -> void:
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	ball.mesh = sphere
	ball.position = at
	ball.material_override = _glass()
	_rig.add_child(ball)
	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.02
	torus.outer_radius = radius + 0.04
	rim.mesh = torus
	rim.position = at
	rim.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	rim.material_override = _paint(GUNMETAL)
	_rig.add_child(rim)


## UNA PANTALLA en un brazo articulado, de `base` a `at`.
func _screen_arm(base: Vector3, at: Vector3) -> void:
	var elbow := (base + at) * 0.5 + Vector3(0.0, 0.2, 0.15)
	_beam(base, elbow, 0.025)
	_beam(elbow, at, 0.022)
	var holder := Node3D.new()
	holder.position = at
	_rig.add_child(holder)
	holder.look_at(_rig.global_transform * Vector3(0.0, 1.1, 0.0), Vector3.UP)
	holder.rotate_object_local(Vector3.UP, PI)
	Clay.box(holder, Vector3(0.26, 0.18, 0.03), Vector3.ZERO, PLATE)
	_controls(holder, Vector2(0.26, 0.18))


## UNA VIGA de `from` a `to`, de `radius`.
func _beam(from: Vector3, to: Vector3, radius: float) -> void:
	var piece := Clay.cylinder(_rig, radius, from.distance_to(to), (from + to) * 0.5, GUNMETAL)
	var along := (to - from).normalized()
	var side := along.cross(Vector3.FORWARD if absf(along.y) > 0.5 else Vector3.UP).normalized()
	piece.basis = Basis(side, along, side.cross(along))


## UN TABLERO de `size` en `at`, inclinado `tilt` grados (hacia atrás, negativo) y girado `turn` en Y, con sus controles
## mirando al artillero.
func _board(at: Vector3, size: Vector2, tilt: float, turn := 0.0) -> void:
	var holder := Node3D.new()
	holder.position = at
	holder.basis = Basis(Vector3.UP, deg_to_rad(turn)) * Basis(Vector3.RIGHT, deg_to_rad(tilt))
	_rig.add_child(holder)
	Clay.box(holder, Vector3(size.x, size.y, 0.02), Vector3.ZERO, PLATE)
	_controls(holder, size)


## LOS CONTROLES en la cara de un tablero de `size` (+Z): munición por color, relojes, calor y recargas.
func _controls(panel: Node3D, size: Vector2) -> void:
	var front := 0.015
	var w := size.x
	var h := size.y
	for k in 3:
		Clay.box(panel, Vector3(w * 0.12, h * 0.16, 0.012), Vector3(-w * 0.32 + k * w * 0.16, -h * 0.28, front), AMMO[k])
	for k in 2:
		var dial := Vector3(-w * 0.3 + k * w * 0.22, h * 0.16, front)
		Clay.cylinder(panel, minf(w, h) * 0.13, 0.008, dial, SCREEN, Vector3(90.0, 0.0, 0.0))
	Clay.box(panel, Vector3(w * 0.06, h * 0.7, 0.01), Vector3(w * 0.4, 0.0, front), SCREEN)
	Clay.box(panel, Vector3(w * 0.05, h * 0.45, 0.012), Vector3(w * 0.4, -h * 0.12, front + 0.002), RED)
	for k in 3:
		var y := h * (0.28 - k * 0.12)
		Clay.box(panel, Vector3(w * 0.22, h * 0.07, 0.01), Vector3(w * 0.15, y, front), SCREEN)
		Clay.box(panel, Vector3(w * 0.22 * (0.3 + k * 0.3), h * 0.06, 0.012), Vector3(w * 0.15 - w * 0.11 * (0.7 - k * 0.3), y, front + 0.002), GREEN)


## ── EL MANIQUÍ ───────────────────────────────────────────────────────────────────────────────────────────────────

## EL MANIQUÍ con las manos en `_hands`: sentado (o parado, `_standing`), hundido `_sunk` m, mirando hacia `_facing`.
func _dummy() -> void:
	var skin := Color(0.85, 0.72, 0.6)
	var cloth := Color(0.35, 0.42, 0.55)
	var body := Node3D.new()
	body.position = Vector3(0.0, -_sunk, 0.0)
	_rig.add_child(body)
	_rig.transform = _chair.transform * Transform3D(Basis(Vector3.UP, _facing), Vector3.ZERO)
	var hip_y := 1.0 if _standing else HIP
	var top := hip_y + (SHOULDER - HIP)
	Clay.box(body, Vector3(0.36, top - hip_y, 0.22), Vector3(0.0, (top + hip_y) * 0.5, 0.05), cloth)
	Clay.sphere(body, 0.12, Vector3(0.0, top + 0.18, 0.04), skin)
	for i in 2:
		var s := -1.0 if i == 0 else 1.0
		var shoulder := Vector3(s * 0.21, top - 0.04, 0.05)
		var hand: Vector3 = _hands[i] + Vector3(0.0, _sunk, 0.0)
		var elbow := (shoulder + hand) * 0.5 + Vector3(s * 0.08, -0.16, 0.08)
		_limb(body, shoulder, elbow, 0.05, cloth)
		_limb(body, elbow, hand, 0.045, cloth)
		Clay.sphere(body, 0.05, hand, skin)
		var hip := Vector3(s * 0.12, hip_y, 0.05)
		if _standing:
			_limb(body, hip, Vector3(s * 0.14, 0.05, 0.05), 0.07, cloth)
		else:
			var knee := Vector3(s * 0.16, hip_y, -0.38)
			_limb(body, hip, knee, 0.07, cloth)
			_limb(body, knee, knee + Vector3(0.0, -0.45, 0.02), 0.06, cloth)


func _limb(parent: Node3D, from: Vector3, to: Vector3, radius: float, color: Color) -> void:
	var piece := Clay.cylinder(parent, radius, from.distance_to(to), (from + to) * 0.5, color)
	var along := (to - from).normalized()
	var side := along.cross(Vector3.FORWARD if absf(along.y) > 0.5 else Vector3.UP).normalized()
	piece.basis = Basis(side, along, side.cross(along))


func _paint(color: Color) -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	return paint


func _glass() -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = GLASS
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return paint


## ── LAS FOTOS ────────────────────────────────────────────────────────────────────────────────────────────────────

func _label(layer: CanvasLayer, at: Vector2, size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.size = Vector2(VIEW.x - at.x * 2.0, 0.0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 10)
	layer.add_child(label)
	return label


func _shot(name_of: String, note: String, from: Vector3, to: Vector3, fov: float) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	_title.text = name_of
	_note.text = note
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_shots.append(get_viewport().get_texture().get_image())


## UNA HOJA: dos columnas (de costado, desde sus ojos), una fila por idea; y vacía la lista.
func _save(number: int) -> void:
	if _shots.is_empty():
		return
	var first: Image = _shots[0]
	var w := first.get_width() / 2
	var h := first.get_height() / 2
	var sheet := Image.create(w * 2, h * ceili(_shots.size() / 2.0), false, first.get_format())
	for index in _shots.size():
		var shot: Image = _shots[index]
		shot.resize(w, h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/artillero_%d.png" % [_folder, number]
	sheet.save_png(path)
	print("CAPTURA ", path)
	_shots.clear()
