class_name MechSkills
extends RefCounted

## LAS HABILIDADES SON ZONAS (22/11/2026; el usuario: «no es buena práctica que el mecha pueda hacer daño fuera de su zona de
## visión… todas las habilidades tienen una hitbox… zonas en cono o en línea, pero con límite»). Cada una dice su forma; se
## dibuja en el piso mientras se mantiene su tecla (MechAim) y al salir le pega a lo que esté adentro. El brazo es animación.
## LOS LARGOS SON PARTES DE UN SOLO NÚMERO (HitSettings.skill_range; el usuario: «que permita cambios en el futuro sin tener
## que volver a cambiar todos los rangos»). No sigue al zoom solo: acercar la cámara no tiene que cambiar el balance. Si
## cambia la cámara se mueve ese número; el F4 dice cuánto se ve con el zoom de ahora (`visible_reach`).

## El tope de la mira con los valores de arranque (m). Lo de verdad, `reach_limit`.
const RANGE := 14.0
## El golpe que recibe un jefe de una piña a fuerza 1 (lo que daba el golpe físico: 7 t a 35 m/s).
const STRIKE_IMPULSE := 245000.0
const TINT := Color(0.25, 0.7, 1.0)
const BLAST := Color(1.0, 0.95, 0.75)
const BLAST_TIME := 0.18


## Hasta dónde llega cualquier habilidad (m).
static func reach_limit() -> float:
	return HitSettings.current.skill_range


## LO QUE SE VE EN EL PISO HACIA ABAJO DE LA PANTALLA desde el personaje (m): el lado más corto.
static func visible_reach() -> float:
	var view := IsoSettings.current
	var pitch := deg_to_rad(view.pitch)
	var zoom := MatchSettings.current.zoom_aboard
	if view.orthographic:
		return zoom * 0.5 / maxf(sin(pitch), 0.1)
	var half := deg_to_rad(view.fov) * 0.5
	var away := maxf(zoom * 0.5 / tan(half), IsoView.MIN_AWAY)
	return away * cos(pitch) - away * sin(pitch) / tan(minf(pitch + half, PI * 0.49))


static func cone(half: float, share: float) -> Dictionary:
	return {"shape": BossZone.Shape.CONE, "size": half, "length": share * reach_limit()}


static func line(width_share: float, share: float) -> Dictionary:
	return {"shape": BossZone.Shape.STRIP, "size": width_share * reach_limit(), "length": share * reach_limit()}


static func circle(share: float) -> Dictionary:
	return {"shape": BossZone.Shape.CIRCLE, "size": share * reach_limit(), "length": 0.0}


static func fist() -> Dictionary:
	return cone(HitSettings.current.fist_half, HitSettings.current.fist_reach)


static func pole() -> Dictionary:
	return line(HitSettings.current.pole_width, HitSettings.current.pole_reach)


static func spin() -> Dictionary:
	return cone(HitSettings.current.spin_half, HitSettings.current.spin_reach)


## El cañón: cargarlo lo alarga.
static func cannon(charge: float) -> Dictionary:
	var knobs := HitSettings.current
	return line(knobs.cannon_width, lerpf(knobs.cannon_short, knobs.cannon_long, clampf(charge, 0.0, 1.0)))


static func minigun() -> Dictionary:
	return line(HitSettings.current.minigun_width, HitSettings.current.minigun_reach)


static func missile() -> Dictionary:
	return circle(HitSettings.current.missile_radius)


static func shield() -> Dictionary:
	return cone(HitSettings.current.shield_half, HitSettings.current.shield_reach)


## Si `zone`, puesta en `origin` hacia `way`, toca un círculo de `half` en `point`.
static func covers(zone: Dictionary, origin: Vector3, way: Vector3, point: Vector3, half: float) -> bool:
	return BossZone.shape_covers(zone["shape"], zone["size"], zone["length"], origin, way, point, half)


## LE PEGA A TODO LO QUE ESTÉ ADENTRO: los blancos (HitTarget) y lo suelto. El daño lo aplica sólo el host. Devuelve a
## cuántos tocó.
static func land(mech: Node3D, zone: Dictionary, origin: Vector3, way: Vector3, source: String, power: float,
		strength: float) -> int:
	var count := 0
	for node in mech.get_tree().get_nodes_in_group(HitTarget.GROUP):
		var target := node as HitTarget
		if target.alive() and covers(zone, origin, way, target.center(), target.flat_radius()):
			target.strike(source, power, strength, target.surface(origin), way)
			count += 1
	if ProjectileField.is_client(mech):
		return count
	var ball := SphereShape3D.new()
	ball.radius = maxf(zone["length"], zone["size"] if zone["shape"] == BossZone.Shape.CIRCLE else 0.0) + 1.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = ball
	query.transform = Transform3D(Basis(), origin)
	query.collision_mask = EnergyBolt.MASK
	var seen := {}
	for found in mech.get_world_3d().direct_space_state.intersect_shape(query, 32):
		var body := EnergyBolt.struck(found["collider"])
		if body == null or body == mech or seen.has(body.get_instance_id()) or HitTarget.of_body(body) != null:
			continue
		seen[body.get_instance_id()] = true
		if covers(zone, origin, way, body.global_position, 0.5):
			EnergyBolt.lands(body, way * strength, body.global_position, source, power)
			count += 1
	return count


## LO QUE SE VE AL SALIR: la zona entera, clara, un instante.
static func blast(parent: Node, zone: Dictionary, origin: Vector3, way: Vector3) -> void:
	var mark := BossZone.skill(parent, BLAST)
	mark.shape = zone["shape"]
	mark.size = zone["size"]
	mark.length = zone["length"]
	mark.locked = true
	mark.place(origin, way)
	parent.get_tree().create_timer(BLAST_TIME).timeout.connect(mark.queue_free)
