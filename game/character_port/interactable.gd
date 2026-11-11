class_name Interactable
extends Node3D

## PIEZA PARA LOS PERSONAJES DE CHARACTER-PARAMETRIC (ver LEEME.md de esta carpeta): allá esto es la base de todo lo que se toca, copiada entera; la base de allá (SoundEntity) es un Node3D con sonidos;
## acá sólo está lo que los personajes le piden.

## Todo lo que se toca puede sonar: declara sus sonidos en `SOUNDS` (ver SoundEntity).

var handle_points: Array[Node3D] = []

## ── CÓMO SE TOMA, DE CERO (29/10/2026) ──────────────────────────────────────────────────────────────────────────
## Lo pidió el dios del juego: todo lo de la animación de las manos «empezar todo de cero… dividir todos los tipos de
## agarre posibles en categorías y después ir tacleando categoría por categoría». Las seis maneras de antes (envolver,
## pinza, cubrir, apoyar, sostener), con sus poses, su dirección por punto y su tensión de muñeca, se borraron; quedan los
## puntos de donde se toma cada cosa. Las categorías vuelven de a una:
##   · APRETAR (PRESS): con el puño o con el índice (se prueban las dos, ver TubeHand.press_with) —un botón, una tecla,
##     una ranura—. Ver ArmsController.
##   · EMPUÑAR (WRAP): el puño cerrado alrededor de un aro —un volante, una válvula— o de una barra que se mueve —una
##     palanca, la perilla de una manivela, los cuernos de un mando—: el hueco del puño en el punto y la mano girada
##     sobre el antebrazo hasta que los nudillos siguen el aro o la barra (la dirección del punto, ver
##     `add_handle_point_local`). Ver ArmsController.
##   · NINGUNA (NONE): lo que todavía no tiene categoría. El brazo lleva el medio de la palma al punto, la mano derecha.
enum Grip { NONE, PRESS, WRAP }

## Cómo se toma (ver arriba).
func grip_kind() -> Grip:
	return Grip.NONE

## CON CUÁNTAS MANOS SE AGARRA: una o dos (lo decidió el dios del juego, 11/10/2026). Lo de casi todo sale de sus
## puntos: uno, una mano; más, dos. Lo que gira lo pisa por su tamaño (ver RotatingComponent): una perilla tiene varios
## puntos en su borde y se gira con una mano.
func hands() -> int:
	return 1 if handle_points.size() <= 1 else 2

## DÓNDE SE LA TIENE: lo que decide con qué mano se toma (ver ArmsController). Lo de casi todo, donde está; lo que se
## sostiene, donde va a estar en la mano (ver HeldInteractable).
func grip_center() -> Vector3:
	return global_position

## Un punto de donde se lo toma, en `local_pos`; `axis`, una dirección de ese punto en el marco de la pieza (el aro de
## un volante, el eje de una manivela), guardada para las categorías que la necesiten.
func add_handle_point_local(local_pos: Vector3, axis := Vector3.ZERO) -> void:
	var pt := Node3D.new()
	pt.position = local_pos
	if axis != Vector3.ZERO:
		pt.set_meta("axis", axis)
	add_child(pt)
	handle_points.append(pt)

func get_nearest_handle_point(world_pos: Vector3, exclude: Node3D = null) -> Node3D:
	var best: Node3D = null
	var best_dist := INF
	for pt in handle_points:
		if not is_instance_valid(pt) or pt == exclude:
			continue
		var d := pt.global_position.distance_to(world_pos)
		if d < best_dist:
			best_dist = d
			best = pt
	return best

func can_interact() -> bool:
	return true

## Nodos cuyos meshes se contornean al mirar este interactuable. Por defecto el propio
## interactuable (dashboards/controllables contienen su malla). Un grabbable representa al
## objeto sobre el que cuelga (su padre) → lo overridea.
func get_outline_targets() -> Array[Node]:
	var targets: Array[Node] = [self]
	return targets

func _clear_handle_points() -> void:
	for pt in handle_points:
		if is_instance_valid(pt):
			pt.queue_free()
	handle_points.clear()
