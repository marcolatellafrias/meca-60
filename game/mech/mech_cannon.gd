class_name MechCannon
extends MechArm

## EL CAÑÓN: dispara una bala pesada (MechShell) hacia donde apunta. El retroceso empuja a la meca para atrás y el caño
## se recoge un momento. Recarga en `RELOAD` segundos.

const RELOAD := 0.7
const MUZZLE := 5.6
const KICK := 0.8

var _barrel: Node3D = null
var _wait := 0.0


func _build() -> void:
	Clay.box(pivot, Vector3(1.6, 1.6, 2.4), Vector3(0, 0, -1.2), Clay.METAL.darkened(0.1))
	_barrel = Node3D.new()
	pivot.add_child(_barrel)
	Clay.cylinder(_barrel, 0.45, 3.4, Vector3(0, 0, -3.9), Clay.DARK, Vector3(90, 0, 0))
	Clay.cylinder(_barrel, 0.6, 0.5, Vector3(0, 0, -5.4), Clay.DARK.darkened(0.3), Vector3(90, 0, 0))


func ready_to_use() -> bool:
	return _wait <= 0.0


func use() -> bool:
	if _wait > 0.0:
		return false
	_wait = RELOAD
	var shell := MechShell.new()
	get_tree().current_scene.add_child(shell)
	var direction := pointing()
	shell.launch(pivot.global_position + direction * MUZZLE, direction)
	_barrel.position.z = 1.2
	kicked.emit(-direction, KICK)
	return true


func _process(delta: float) -> void:
	_wait = maxf(_wait - delta, 0.0)
	_barrel.position.z = move_toward(_barrel.position.z, 0.0, 3.0 * delta)
