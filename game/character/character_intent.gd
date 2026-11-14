class_name CharacterIntent
extends RefCounted

## ── LO QUE QUIERE HACER (03/11/2026) ─────────────────────────────────────────────────────────────────────────────────
## LA MISMA INTENCIÓN PARA TODOS LOS QUE MANEJAN: el teclado (PlayerController), la red (CharacterNetSync) y el guion
## (ExhibitOperator) escriben esto, y el cuerpo lo hace igual venga de donde venga —nadie más le toca la mirada, el paso,
## las manos o la silla—. Lo pidió el usuario: el piloto de exhibición doblaba el volante sin mirar hacia la curva,
## cosa que un jugador sí hace, porque el guion tenía un camino aparte (`seated_turn`, `head_pitch`). Vive en
## `BoneInstantiator.intent`, y el cuerpo físico lee el mismo objeto.
##
## LA MIRADA VA EN LOS EJES DEL MARCO (ver MotionFrame, CharacterRigidBody3D.frame), o del mundo si no tiene: así viaja
## sola con la meca, y nada tiene que sumarle lo que la meca giró. Rumbo y cabeceo en radianes; el rumbo, hacia −Z
## girando a la izquierda (+), como un `rotation.y`.

var look_yaw := 0.0
var look_pitch := 0.0
## ADÓNDE VA, en los ejes de la mirada: x a la derecha, y hacia atrás (como `Input.get_axis("move_forward",
## "move_backward")`), cada uno de −1 a 1. Y si corre.
var move := Vector2.ZERO
var sprint := false
## EL SALTO, MANTENIDO: mientras está, carga; al soltarlo, salta lo cargado (ver BoneInstantiator, EL SALTO CARGADO). Es
## la barra espaciadora del jugador y el `jump_at` del guion.
var jump := false
## AGACHARSE, MANTENIDO (05/11/2026): mientras está, agachado. El cuerpo baja y sube igual venga de donde venga (ver
## BoneInstantiator._update_crouch). Es el Ctrl del jugador y el `crouch` del guion. *Hasta entonces el jugador y el
## guion se agachaban cada uno con su propio código.*
var crouch := false
## LAS MANOS, LOS MISMOS BOTONES PARA TODOS (05/11/2026, el usuario: «un solo sistema… para atajar, para mover,
## para todo»): los aprieta el teclado o el guion, y los lee el controlador de interacción de cada uno
## (InteractionController._read_intent). `use`, el clic: mientras está, agarra o usa lo que mira; al soltarlo, lo suelta.
## `throw`, la R: mientras está, carga el tiro —o el empujón, con las manos vacías—; al soltarlo, tira. `turn_held`, el
## clic derecho: el mouse gira lo que lleva. `hand_motion`, el mouse para las manos (px; lo consume el controlador).
## `reach_steps`, la ruedita (muescas pendientes). `activate`, la E (un toque; lo consume el controlador).
var use := false
var throw := false
var turn_held := false
var hand_motion := Vector2.ZERO
var reach_steps := 0.0
var activate := false
## EL TURBO del ente (ver CharacterRigidBody3D, MOVIMIENTO DIRECTO): 0 sin turbo, 1 con dos toques de shift (cuatro
## veces más), 2 con tres (otras cuatro veces más, para cruzar el sandbox).
var turbo := 0
## QUÉ AGARRA (un Interactable: lo que lleva, el control que maneja) o null; y, si quien lo maneja lo eligió, a qué punto
## de agarre va (si no, al más cercano al agarrar). Los brazos van por un solo camino (ArmsController.drive_grab).
var grab: Node = null
var grab_point: Node3D = null
## EN QUÉ SILLA ESTÁ SENTADO (un SeatInteractable) o null. Al jugador lo sienta la silla cuando el host se la da, y la
## silla lo anota acá; a los demás, esto los sienta (ver BoneInstantiator._follow_seat).
var seat: Node = null


## EL RUMBO DE `world_dir` (sólo cuenta lo horizontal del marco) en los ejes de `frame`, o del mundo sin marco.
static func yaw_of(frame: Node3D, world_dir: Vector3) -> float:
	var local := frame.global_basis.orthonormalized().inverse() * world_dir if frame != null else world_dir
	return atan2(-local.x, -local.z)


## EL RUMBO EN EL MUNDO que corresponde a `yaw` en los ejes de `frame`: lo que gira una cápsula que va derecha.
static func world_yaw(frame: Node3D, yaw: float) -> float:
	if frame == null:
		return yaw
	var dir := frame.global_basis.orthonormalized() * (Basis(Vector3.UP, yaw) * Vector3.FORWARD)
	return atan2(-dir.x, -dir.z)
