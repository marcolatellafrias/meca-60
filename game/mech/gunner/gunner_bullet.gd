class_name GunnerBullet
extends Node3D

## UNA BALA DE LA AMETRALLADORA: SÓLO SE VE (22/11/2026; el usuario: «toda la zona de balas sean una sola zona… las balas
## de por sí sean más algo estético»). Lo que pega es la zona de MechGuns. La trazadora va derecho a `SPEED`, se apaga en lo
## fijo o al llegar a `reach`, y deja chispas SÓLO SI TOCÓ ALGO (lo fijo, o el blanco de la zona: `lands`). Cada máquina dibuja las suyas.

const SPEED := 260.0
const LIFE := 1.6
const TRACER := Color(1.0, 0.85, 0.45)

## Lo que no la frena (la meca que la tira) y hasta dónde va (m; negativo, hasta que choque o se apague).
var skip: Array[RID] = []
var reach := -1.0
## Si al final de `reach` hay un blanco.
var lands := false
## Su color (el de la munición que lleva).
var tint := TRACER
var _age := 0.0
var _flown := 0.0
## Cuántas se dibujaron en esta máquina (para los tests de red).
static var made := 0


func _ready() -> void:
	made += 1
	var tracer := Clay.box(self, Vector3(0.07, 0.07, 2.4), Vector3(0.0, 0.0, 1.2), tint)
	tracer.material_override = EnergyBolt.shine(tint)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > LIFE:
		queue_free()
		return
	var from := global_position
	var step := SPEED * delta
	var arrives := reach >= 0.0 and _flown + step >= reach
	if arrives:
		step = reach - _flown
	var to := from - global_basis.z * step
	var query := PhysicsRayQueryParameters3D.create(from, to, PhysicsLayers.FIXED, skip)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() or arrives:
		if not hit.is_empty() or lands:
			var at: Vector3 = hit["position"] if not hit.is_empty() else to
			GunnerFx.sparks(at, 0.35)
			MechSounds.loose(MechSounds.BULLET_HIT, at, get_tree(), randf_range(0.85, 1.15), 0.5)
		queue_free()
		return
	_flown += step
	global_position = to
