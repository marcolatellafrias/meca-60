extends Node

## LA REGLA DE LAS CAJAS DE GOLPE (sin ventana, unos 10 segundos; 18/11/2026): donde se le pega a algo sale de lo que
## viaja por la red, y se le pega donde se lo ve.
##   · LA MECA AGACHADA: el blanco donde le pegan los jefes (BrawlerBrain.touches_target) baja con ella. Un punto a
##     mitad de camino entre lo alto agachada y lo alto parada le pega parada y le pasa por arriba agachada.
##   · EL JEFE: lo de arriba de donde se le pega (BossHurtbox.upper) sigue a su torso. Un rayo de frente, a la altura
##     del pecho, encuentra la caja donde está el frente del pecho dibujado: quieto, con el torso inclinado por un golpe
##     y agachado para cavar (la pose DIG, 42° adelante).

var _boss: Brawler = null
var _mech: ToolMech = null
var _brain: BrawlerBrain = null


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var parent := Node3D.new()
	add_child(parent)
	BrawlerArchetype.thinking = false
	BrawlerSettings.current.rage.every = 0.0
	var root := BrawlerArchetype.new().build(0, parent)
	_boss = root.get_node("Luchador") as Brawler
	await _wait(0.5)
	_brain = _boss.get_node("Cabeza") as BrawlerBrain
	_mech = _brain.target as ToolMech
	_mech.scripted = true
	_boss.put(Transform3D(Basis(), Vector3.ZERO))
	_mech.put(Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 0.0, -150.0)))
	await _wait(0.5)
	await _crouch()
	await _chest()
	get_tree().quit()


func _crouch() -> void:
	var standing := _mech.mover.tall_now()
	_mech.crouch = true
	await _wait(1.5)
	var crouched := _mech.mover.tall_now()
	var at := _mech.mover.global_position
	var point := at + Vector3.UP * (standing + crouched) * 0.5
	var hits_low := _brain.touches_target(point, 0.0)
	_mech.crouch = false
	await _wait(1.5)
	var hits_up := _brain.touches_target(point, 0.0)
	print("LA MECA: alta %.2f m parada y %.2f agachada · un golpe a %.2f m le pega parada %s y agachada %s" % [standing,
		crouched, point.y - at.y, hits_up, hits_low])


func _chest() -> void:
	print("EL JEFE QUIETO: %s" % _chest_gap())
	var worst := 0.0
	var tilt := 0.0
	_boss.body_spring.hit(Vector2(0.0, -12.0), 1.0, false)
	for i in 30:
		await get_tree().physics_frame
		var gap := _front_gap()
		tilt = maxf(tilt, absf(_boss.body_spring.tilt_degrees().x))
		if not is_nan(gap):
			worst = maxf(worst, absf(gap))
	print("EL JEFE INCLINADO por un golpe (hasta %.1f°): la caja, a lo más a %.2f m del frente del pecho dibujado" % [tilt, worst])
	_boss.pose = Brawler.Pose.DIG
	await _wait(2.0)
	print("EL JEFE AGACHADO PARA CAVAR: %s" % _chest_gap())
	_boss.pose = Brawler.Pose.REST


func _chest_gap() -> String:
	var gap := _front_gap()
	if is_nan(gap):
		return "el rayo no encuentra la caja a la altura del pecho"
	return "la caja a %.2f m del frente del pecho dibujado" % gap


## Lo que hay entre donde un rayo de frente encuentra la caja y el frente del pecho dibujado, a la altura del pecho (m;
## positivo, la caja más adelante). NAN si el rayo no la encuentra.
func _front_gap() -> float:
	var size := Brawler.scale()
	var chest_y := BrawlerBody.WAIST.y + BrawlerBody.CHEST.y * 0.5
	var front: Vector3 = _boss.body.bent.global_transform * Vector3(0.0, chest_y, -BrawlerBody.CHEST.z * 0.5)
	var query := PhysicsRayQueryParameters3D.create(Vector3(front.x, front.y, front.z - 60.0 * size),
		Vector3(front.x, front.y, front.z + 30.0 * size), 1)
	query.collide_with_areas = false
	var hit := get_viewport().get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or not hit["collider"] is BossHurtbox:
		return NAN
	return front.z - (hit["position"] as Vector3).z


func _wait(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
