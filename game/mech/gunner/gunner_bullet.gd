class_name GunnerBullet
extends Node3D

## UNA BALA DE LA MINIGUN DEL ARTILLERO (ver GunnerWeapons): una trazadora fina que va derecho a `SPEED`, y en cada paso
## barre su camino con un rayo. Lo que toca: lo suelto (un jefe, por la caja donde se le pega) recibe el golpe
## (EnergyBolt.lands: el empujón y, si lo lleva, el daño), y lo fijo (una pared, el cuerpo de un jefe) la frena; las dos
## cosas dejan chispas. PERFORANTE (`pierce`): sigue de largo después de pegarle a lo suelto. Todavía no viaja por red.

const SPEED := 260.0
const LIFE := 1.6
## El empujón de una bala (kg·m/s): lo que le dice a lo que pega (ver EnergyBolt.lands).
const IMPULSE := 15000.0
## Lo que choca: lo suelto (y donde se le pega a un jefe) y lo fijo del mundo.
const MASK := 1 | PhysicsLayers.FIXED
const TRACER := Color(1.0, 0.85, 0.45)

var pierce := false
## Cuánto más fuerte (×): la recarga con ritmo bien hecha.
var strength := 1.0
## Lo que no tiene que tocar (la meca que la tira).
var skip: Array[RID] = []
var _age := 0.0


func _ready() -> void:
	var tracer := Clay.box(self, Vector3(0.025, 0.025, 1.4), Vector3(0.0, 0.0, 0.7), TRACER)
	var paint := EnergyBolt.shine(TRACER)
	tracer.material_override = paint


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > LIFE:
		queue_free()
		return
	var from := global_position
	var to := from - global_basis.z * SPEED * delta
	var space := get_world_3d().direct_space_state
	for attempt in 4:
		var query := PhysicsRayQueryParameters3D.create(from, to, MASK, skip)
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			break
		var at: Vector3 = hit["position"]
		GunnerFx.sparks(at, 0.35)
		var body := EnergyBolt.struck(hit["collider"])
		if body != null:
			EnergyBolt.lands(body, -global_basis.z * IMPULSE * strength, at, "minigun")
			if pierce:
				skip.append(hit["rid"])
				continue
		queue_free()
		return
	global_position = to
