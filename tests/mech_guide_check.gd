extends Node

## ENCAMINAR LAS ARMAS CON EL MOUSE (con ventana, unos 25 s): la mira sigue al mouse; la ametralladora gira sola a su
## velocidad, le pega a un blanco al costado sin que gire el torso, respeta su arco y vuelve al soltarla; el misil dobla
## hacia la mira. No guarda nada. Termina con GUIADO OK o GUIADO MAL.
##   tools/godot_ventana.sh res://tests/mech_guide_check.tscn

const PEER := 999
const BAG_AT := Vector3(8.0, 9.0, 0.0)

var _bad := 0
var _mech: CageMech = null
var _crew: MechCrew = null
var _bag: HitTarget = null


func _ready() -> void:
	# Esta prueba es de las teclas: no depende de lo que el usuario tenga guardado en el F6.
	MatchSettings.current.controls = MatchSettings.Controls.KEYS
	get_window().size = Vector2i(1280, 720)
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(300, 1, 300), Vector3(0, -0.5, 0))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var rig := BaseBagRig.new()
	rig.position = BAG_AT
	add_child(rig)
	rig.build(0.9, 3.6, 4.3, Color(0.55, 0.33, 0.25))
	_bag = rig.target
	_mech = CageMech.new()
	_mech.loadout = [ArmLoadout.of(ArmLoadout.Tip.FIST),
		ArmLoadout.of(ArmLoadout.Tip.CANNON)]
	_mech.position = Vector3(0.0, Mech.standing_height(_mech.cabin_shape), 0.0)
	add_child(_mech)
	await _wait(0.8)
	_crew = _mech.get_node("Tripulacion") as MechCrew
	_reticle()
	await _gun()
	await _missile()
	print("GUIADO OK" if _bad == 0 else "GUIADO MAL (%d)" % _bad)
	get_tree().quit(_bad)


func _reticle() -> void:
	var me := multiplayer.get_unique_id()
	var aim := _crew.aim
	aim.store(me, Vector3.ZERO)
	var view := IsoSettings.current
	var pixels := get_viewport().get_visible_rect().size.y * 0.25
	aim.move(Vector2(pixels, 0.0))
	var meters := view.zoom * 0.25 * HitSettings.current.aim_sensitivity
	var moved := aim.point_of(me) - _mech.global_position
	var expected := view.screen_to_world(Vector2.RIGHT) * meters
	_check("la mira sigue al mouse en la pantalla", moved.distance_to(expected) < 0.05)
	aim.move(Vector2(pixels * 100.0, 0.0))
	var far := (aim.point_of(me) - _mech.global_position).length()
	_check("la mira no pasa del alcance", far <= MechGuns.ZONE_LENGTH + 0.01)
	aim._offsets.erase(me)


func _gun() -> void:
	var knobs := HitSettings.current
	var yaw := _mech.yaw()
	var hits := _bag.hits
	_crew.aim.store(PEER, BAG_AT * Vector3(1.0, 0.0, 1.0))
	_crew._store(PEER, 1 << MechCrew.MINIGUN)
	await _wait(0.25)
	var early := absf(_mech.guns._gun_turn)
	_check("gira a su velocidad, no de golpe", early > 0.1 and early < deg_to_rad(knobs.gun_turn) * 0.35)
	await _wait(1.9)
	print("ametralladora: giró %.0f°, %d pulsos" % [rad_to_deg(_mech.guns._gun_turn), _bag.hits - hits])
	_check("apunta al blanco del costado", absf(absf(rad_to_deg(_mech.guns._gun_turn)) - 90.0) < 3.0)
	_check("le pega sin girar el torso", _bag.hits > hits + 3 and absf(angle_difference(yaw, _mech.yaw())) < 0.03)
	# DA LA VUELTA ENTERA: un blanco justo atrás del torso.
	_crew.aim.store(PEER, Basis(Vector3.UP, _mech.yaw()) * Vector3.BACK * 9.0)
	await _wait(2.2)
	_check("apunta atrás, desde su torreta", absf(absf(rad_to_deg(_mech.guns._gun_turn)) - 180.0) < 10.0)
	_crew._store(PEER, 0)
	_crew.aim._offsets.erase(PEER)
	await _wait(2.5)
	_check("al soltarla vuelve al frente", absf(_mech.guns._gun_turn) < 0.02)
	_mech.guns.weapons.heat = 0.0
	_mech.guns.weapons.jammed = false
	await _wait(2.5)


func _missile() -> void:
	var hits := _bag.hits
	var dealt := _bag.dealt
	_crew.aim.store(PEER, BAG_AT * Vector3(1.0, 0.0, 1.0))
	_crew._store(PEER, 1 << MechCrew.MISSILES)
	await _wait(0.1)
	_crew._store(PEER, 0)
	await _wait(2.0)
	print("misil: %d golpe, %.1f de daño" % [_bag.hits - hits, _bag.dealt - dealt])
	_check("sale al frente y dobla hasta el blanco del costado", _bag.hits == hits + 1)
	_crew.aim._offsets.erase(PEER)


func _check(what: String, ok: bool) -> void:
	print(("ok   " if ok else "MAL  ") + what)
	_bad += 0 if ok else 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
