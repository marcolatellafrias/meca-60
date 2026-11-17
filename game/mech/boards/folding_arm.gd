class_name FoldingArm
extends ControllableInteractable

## EL BRAZO PLEGABLE DE DOS ARTICULACIONES CON SU MANDO (17/11/2026, el usuario: «vamos con la versión más simple», la
## 1 de tests/folding_arm_ideas_look: barras redondas y rótulas). Sale de su base en la grilla de una cara (lo arma
## FoldingArmArchetype, y va en su tablero como cualquier pieza, FaceMount) y lleva un mando de palo en la punta.
##
## ES UN CONTROL CON MODO (ver ControllableInteractable.has_mode): con el clic izquierdo, como cualquier control, la mano
## va al mando y nada más; CON EL CLIC DERECHO MANTENIDO se trae a la mano (`brought_tip`) y la mirada se va sola hacia
## adelante (`look_point`, la cúpula); al soltarlo, se pliega contra su cara. El usuario: «lo único que tienen en común
## con los componentes es que podés apuntarlos y podés hacerle clic y tu mano se va hacia cierto punto»; el mouse, en el
## modo, va a hacer lo que hace ese control (mover un brazo de la meca), más adelante.
##
## SU VALOR es dónde está: 0 plegado, 1 traído; va y viene suave (`TRAVEL_S`). Viaja por red como el de cualquier
## control (lo manda quien lo maneja), y en cada máquina el brazo se mueve solo hasta ahí.
##
## LA POSE: dos tramos iguales (`lengths`) de la base a la punta, con el codo hacia `pole` —plegado, hacia abajo, contra
## la cara; traído, hacia afuera y arriba, lejos de la mirada—. Todo en el espacio de la pieza (FoldingArmArchetype): x a
## lo largo de la cara, y hacia arriba, z hacia quien la usa.

## Lo que tarda en ir de plegado a traído (s).
const TRAVEL_S := 0.35

## La base del primer tramo, la rótula de la pieza.
var hub := Vector3(0.0, 0.0, 0.05)
## Plegado: la punta un poco abajo de la base y despegada de la cara (que el que maneja la alcance: el alcance es de 1 m
## desde el pecho, y la cara está casi a eso), el codo abajo.
var folded_tip := Vector3(0.0, -0.1, 0.2)
var folded_pole := Vector3(0.0, -1.0, 0.1)
## Traído: la punta en la mano (la pone quien lo monta, `reach_to`), el codo afuera y arriba.
var brought_tip := Vector3(0.0, -0.1, 0.12)
var brought_pole := Vector3(0.0, 0.5, 0.6)
## Adónde mira el que lo maneja en el modo, en el espacio de la pieza; INF, a ningún lado.
var look_point := Vector3.INF
## Los dos tramos.
var lengths := Vector2(0.3, 0.3)
## «Arriba» y «adelante» de la meca en el espacio de la pieza: el mando va parado y mirando adelante.
var up_here := Vector3.UP
var front_here := Vector3.FORWARD

## Lo que arma FoldingArmArchetype: la raíz de la pieza, los dos tramos y la rótula del codo; el mando es el padre de este
## control.
var piece: Node3D = null
var rods: Array[Node3D] = []
var elbow_ball: Node3D = null

var _t := 0.0


## La TRAE A `hand` y la mirada va a `look`, los dos en el espacio de `space` (un antecesor de la pieza: la cabina), con
## su arriba y su adelante de siempre. Los tramos, del largo justo para llegar con el codo un poco doblado.
func reach_to(hand: Vector3, look: Vector3, space: Node3D) -> void:
	var to_piece := _relative(piece, space).affine_inverse()
	brought_tip = to_piece * hand
	look_point = to_piece * look
	up_here = (to_piece.basis * Vector3.UP).normalized()
	front_here = (to_piece.basis * Vector3.FORWARD).normalized()
	var reach := hub.distance_to(brought_tip)
	lengths = Vector2(reach * 0.56, reach * 0.56)
	_pose()


func grip_kind() -> Grip:
	return Grip.WRAP


func has_mode() -> bool:
	return true


func enter_mode() -> void:
	visual_value = 1.0
	_emit_if_changed(1.0)


func exit_mode() -> void:
	visual_value = 0.0
	_emit_if_changed(0.0)


func mode_look() -> Vector3:
	if not look_point.is_finite() or piece == null:
		return Vector3.INF
	return piece.global_transform * look_point


## El agarre: en el medio del palo.
func _setup_handle_points(_size: Vector3) -> void:
	add_handle_point_local(Vector3(0.0, 0.12, 0.0), Vector3.UP)


func _process(delta: float) -> void:
	var goal := clampf(visual_value, 0.0, 1.0)
	if is_equal_approx(_t, goal):
		return
	_t = move_toward(_t, goal, delta / TRAVEL_S)
	_pose()


## LOS TRAMOS Y EL MANDO, en `_t` (0 plegado, 1 traído), suave en las puntas.
func _pose() -> void:
	if piece == null:
		return
	var s := smoothstep(0.0, 1.0, _t)
	var tip := folded_tip.lerp(brought_tip, s)
	var pole := folded_pole.normalized().slerp(brought_pole.normalized(), s)
	var elbow := elbow_of(hub, tip, lengths, pole)
	if hub.distance_to(tip) > lengths.x + lengths.y:
		tip = elbow + (tip - elbow).normalized() * lengths.y
	_rod(rods[0], hub, elbow)
	_rod(rods[1], elbow, tip)
	elbow_ball.position = elbow
	# El mando, parado y mirando adelante, como la meca.
	var grip := get_parent() as Node3D
	var back := -(front_here - up_here * front_here.dot(up_here)).normalized()
	grip.transform = Transform3D(Basis(up_here.cross(back), up_here, back), tip)


## EL CODO de dos tramos de `lengths` de `a` a `b`, doblado hacia `pole`.
static func elbow_of(a: Vector3, b: Vector3, p_lengths: Vector2, pole: Vector3) -> Vector3:
	var span := b - a
	var d := clampf(span.length(), 0.001, p_lengths.x + p_lengths.y - 0.001)
	var dir := span.normalized()
	var along := (p_lengths.x * p_lengths.x - p_lengths.y * p_lengths.y + d * d) / (2.0 * d)
	var high := sqrt(maxf(p_lengths.x * p_lengths.x - along * along, 0.0))
	var out := pole - dir * pole.dot(dir)
	out = out.normalized() if out.length() > 0.001 else Vector3.UP
	return a + dir * along + out * high


## Dónde está `node` en el espacio de `ancestor`, por la cadena de padres (sin depender de estar en el árbol).
static func _relative(node: Node3D, ancestor: Node3D) -> Transform3D:
	var out := Transform3D.IDENTITY
	var at: Node = node
	while at != null and at != ancestor:
		if at is Node3D:
			out = (at as Node3D).transform * out
		at = at.get_parent()
	return out


## Un tramo (la barra de Clay.limb, de largo 1, acostada sobre Z) de `a` a `b`.
static func _rod(rod: Node3D, a: Vector3, b: Vector3) -> void:
	var along := b - a
	var length := maxf(along.length(), 0.001)
	var up := Vector3.UP if absf(along.normalized().y) < 0.95 else Vector3.BACK
	rod.transform = Transform3D(Basis.looking_at(along / length, up) * Basis.from_scale(Vector3(1.0, 1.0, length)),
		(a + b) * 0.5)
