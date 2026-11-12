class_name LeggedCube
extends HoverCube

## EL CUBO CON PIERNAS: el cubo (HoverCube: flota con el resorte vertical, el golpe lo corre y lo inclina con la línea,
## tropieza, cae con física y se recupera con las toberas) con una PELVIS debajo y DOS PIERNAS, para empezar a ver cómo
## se mueven. Lo pidió el usuario el 12/11/2026 («otra categoría con un cubo con piernas, para empezar a ver cómo se
## mueven»; «el cubo debería tener pelvis, obvio»).
##
## EL CUERPO es el de la meca (MechBody): la cara de abajo del cubo flota a la altura de la cintura, la pelvis cuelga de
## ahí y las piernas, con sus largos y sus pies planos, van de la cadera al piso (las dibuja MechLeg). Las piernas son
## dibujo: el peso lo sigue llevando el resorte, y los golpes los recibe el cubo.
##   · LA PELVIS mira hacia donde caminan las piernas (A/D gira; W/S adelante y atrás) y se inclina con la línea,
##     sobre la cintura, como el cubo.
##   · EL CUBO GIRA APARTE sobre la pelvis, como el torso de la meca: manejándolo, el mouse apunta el torso
##     (`torso_yaw`, en el mundo) y la cámara lo sigue; las piernas giran debajo sin moverlo.
##   · LOS PASOS, POR RADIO (el sistema de los personajes de character-parametric de octubre de 2025): cada pie queda
##     plantado donde pisó hasta que su lugar de descanso —debajo de su cadera, adelantado con la marcha (`step_lead`)—
##     se aleja de él más que `step_radius`; ahí da un paso hasta ese lugar, por el aire, de a un pie por vez. Caminando,
##     girando o corrido por un golpe, los pies lo siguen solos.
## AL CAER SE RECOGEN (lo pidió el usuario: «cuando se vuelca, las piernas… se encogen o se retraen… con una animación de
## easing. Y cuando se enderece… lo mismo… de la forma más rápida… tiene que ser antes»): al tropezar se pliegan
## (`fold_time`) y quedan plegadas tirado y subiendo; en cuanto empieza a enderezarse se estiran (`unfold_time`) hacia
## debajo de las caderas, así al quedar derecho ya está parado. Se pliegan, no se achican: las piezas no se estiran.
##
## Las perillas, en LeggedCubeSettings (el panel F1 de su fila); el F2 lo vuelca.

## Cuántos pasos dio, para mirar.
var steps_taken := 0
## Hacia dónde apunta el torso (el cubo), en el mundo; y su giro sobre la pelvis.
var torso_yaw := 0.0
var twist := 0.0

var _feet: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _step := {}
var _pelvis: MeshInstance3D = null
var _legs: Array[MechLeg] = []
var _planted := false
## Qué tan recogidas están las piernas (0 estiradas, 1 recogidas).
var _tuck := 0.0


func _ready() -> void:
	super()
	name = "Cubo con piernas"
	torso_yaw = global_rotation.y
	_pelvis = Clay.box(self, MechBody.PELVIS_SIZE, Vector3.ZERO, Clay.METAL.darkened(0.15))
	_pelvis.top_level = true
	for i in 2:
		var leg := MechLeg.new()
		add_child(leg)
		_legs.append(leg)


func tuning() -> HoverCubeSettings:
	return LeggedCubeSettings.shared


func _physics_process(delta: float) -> void:
	super(delta)
	_place_body(delta)
	_label.text += " · pasos %d" % steps_taken


## ── LA PELVIS Y LAS PIERNAS ──────────────────────────────────────────────────────────────────────────────────────

func _place_body(delta: float) -> void:
	var knobs := tuning() as LeggedCubeSettings
	var standing := state == State.HOVER
	var bottom := global_transform * Transform3D(Basis(), Vector3(0.0, -SIZE * 0.5, 0.0))
	var waist := bottom
	if standing:
		twist = wrapf(torso_yaw - global_rotation.y, -PI, PI)
		_shape.basis = Basis(Vector3.UP, twist)
		waist = bottom * Transform3D(MechBody.tilt(lean * deg_to_rad(knobs.lean_angle)), Vector3.ZERO)
	_pelvis.global_transform = MechBody.pelvis(waist)
	# RECOGIDAS tirado y subiendo; ESTIRADAS parado y ya al empezar a enderezarse, así llegan antes de quedar derecho.
	var folded := state == State.LIMP or state == State.LIFT
	_tuck = move_toward(_tuck, 1.0 if folded else 0.0,
		delta / maxf(knobs.fold_time if folded else knobs.unfold_time, 0.01))
	var share := smoothstep(0.0, 1.0, _tuck)
	var root := _root()
	if standing:
		if not _planted:
			_feet = [MechBody.foot_rest(root, -1.0), MechBody.foot_rest(root, 1.0)]
			_planted = true
		_stepping(delta, root)
	else:
		_planted = false
		_step = {}
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		# Estiradas: parado, donde pisan; enderezándose, debajo de las caderas (donde va a pisar); recién caído, donde
		# pisaban.
		var ground := _foot_ground(i) if standing else (MechBody.foot_rest(root, side) if state == State.RIGHT
			else _feet[i])
		var open := MechBody.leg(MechBody.hip(waist, side), ground, root.basis)
		_legs[i].pose(_blend(open, _tucked_leg(waist, side), share) if share > 0.001 else open)


## UNA PIERNA RECOGIDA, en el espacio de la cintura: el muslo adelante y casi horizontal, la canilla de vuelta abajo y
## el pie debajo de la cadera, plano con el cuerpo. Se pliega, no se achica: las piezas no se estiran.
func _tucked_leg(waist: Transform3D, side: float) -> Dictionary:
	var hip := Vector3(side * MechBody.HIP_X, -MechBody.HIP_DROP, 0.0)
	var knee := hip + Vector3(0.0, 0.15, -1.0).normalized() * MechBody.THIGH
	var ankle := knee + Vector3(0.0, -0.45, 1.0).normalized() * MechBody.SHIN
	var up := waist.basis.y
	return {
		"thigh": MechBody.segment(waist * hip, waist * knee, up),
		"shin": MechBody.segment(waist * knee, waist * ankle, up),
		"foot": Transform3D(waist.basis, waist * (ankle + Vector3(0.0, MechBody.FOOT_SIZE.y * 0.5 - MechBody.ANKLE,
			-MechBody.FOOT_AHEAD))),
		"knee": waist * knee,
	}


## Entre dos posturas de pierna (ver MechBody.leg).
static func _blend(from: Dictionary, to: Dictionary, share: float) -> Dictionary:
	return {
		"thigh": (from["thigh"] as Transform3D).interpolate_with(to["thigh"], share),
		"shin": (from["shin"] as Transform3D).interpolate_with(to["shin"], share),
		"foot": (from["foot"] as Transform3D).interpolate_with(to["foot"], share),
		"knee": (from["knee"] as Vector3).lerp(to["knee"], share),
	}


## LA RAÍZ: el punto del piso debajo del cubo, mirando hacia donde miran las piernas (de costado, hacia donde mira).
func _root() -> Transform3D:
	var ground := global_position.y - _ground_distance(global_position)
	var forward := -global_basis.z
	forward.y = 0.0
	var yaw := atan2(-forward.x, -forward.z) if forward.length_squared() > 0.01 else global_rotation.y
	return Transform3D(Basis(Vector3.UP, yaw), Vector3(global_position.x, ground, global_position.z))


## LOS PASOS POR RADIO (ver arriba).
func _stepping(delta: float, root: Transform3D) -> void:
	var knobs := tuning() as LeggedCubeSettings
	var flat := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var ahead := Transform3D(root.basis, root.origin + flat * knobs.step_lead)
	if not _step.is_empty():
		var foot := int(_step["foot"])
		_step["clock"] = float(_step["clock"]) + delta
		# Adonde va lo sigue al cuerpo mientras está en el aire.
		_step["to"] = MechBody.foot_rest(ahead, -1.0 if foot == 0 else 1.0)
		if float(_step["clock"]) >= float(_step["time"]):
			_feet[foot] = _step["to"]
			_step = {}
		return
	var worst := -1
	var farthest := knobs.step_radius
	for i in 2:
		var rest := MechBody.foot_rest(ahead, -1.0 if i == 0 else 1.0)
		var away := Vector2(rest.x - _feet[i].x, rest.z - _feet[i].z).length()
		if away > farthest:
			worst = i
			farthest = away
	if worst < 0:
		return
	_step = {"foot": worst, "from": _feet[worst], "to": MechBody.foot_rest(ahead, -1.0 if worst == 0 else 1.0),
		"clock": 0.0, "time": knobs.step_time}
	steps_taken += 1


## Dónde está el pie `index` (0 el izquierdo): donde pisó, o en el aire si es el que da el paso.
func _foot_ground(index: int) -> Vector3:
	if _step.is_empty() or int(_step["foot"]) != index:
		return _feet[index]
	var share := clampf(float(_step["clock"]) / float(_step["time"]), 0.0, 1.0)
	var from: Vector3 = _step["from"]
	var to: Vector3 = _step["to"]
	return from.lerp(to, share) + Vector3.UP * sin(share * PI) * (tuning() as LeggedCubeSettings).step_height


## ── EL TORSO, APARTE ─────────────────────────────────────────────────────────────────────────────────────────────

## El dibujo: inclinado con la línea (sobre la cintura, ver HoverCube) y girado sobre la pelvis.
func _leaning(knobs: HoverCubeSettings) -> Transform3D:
	return super(knobs) * Transform3D(Basis(Vector3.UP, twist), Vector3.ZERO)


## La cámara sigue al torso.
func _view_yaw() -> float:
	return super() + (twist if state == State.HOVER else 0.0)


func _unhandled_input(event: InputEvent) -> void:
	super(event)
	var motion := event as InputEventMouseMotion
	if driving and motion != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and state == State.HOVER:
		torso_yaw -= motion.relative.x * 0.0025 * GameOptions.mouse_sensitivity
		get_viewport().set_input_as_handled()


## AL TROPEZAR, el giro del torso pasa al cuerpo (con la línea, que se mide en el espacio del cuerpo): cae como se veía.
func _trip(knobs: HoverCubeSettings) -> void:
	if absf(twist) > 0.0001:
		var undo := Basis(Vector3.UP, -twist)
		var lean_3d := undo * Vector3(lean.x, 0.0, -lean.y)
		var speed_3d := undo * Vector3(_lean_speed.x, 0.0, -_lean_speed.y)
		global_basis = global_basis * Basis(Vector3.UP, twist)
		lean = Vector2(lean_3d.x, -lean_3d.z)
		_lean_speed = Vector2(speed_3d.x, -speed_3d.z)
		twist = 0.0
		_shape.basis = Basis()
	super(knobs)


func _recovered() -> void:
	super()
	torso_yaw = global_rotation.y
	twist = 0.0
