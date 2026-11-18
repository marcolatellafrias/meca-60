extends Node

## ATRAVESAR O FRENARSE DONDE PEGA, DE CERCA Y DE LEJOS (17/11/2026; el usuario: «dos capas… una, la de músculos que
## pegan… y otra que haga de que literalmente la zona de impacto colisione… y ver cómo queda cada una»; «si le pegas muy
## de cerca, no le vas a hacer tanto daño como si le pegaras de lejos justo con el rango al máximo»): la meca jaula le
## pega al Luchador quieto con el brazo derecho (con músculos, que atraviesa): el puño pesado con un directo y el palo
## con su mazazo (PoleTip.CHOP). Cada uno de las dos maneras (A: atraviesa; B: se frena donde pega, ver
## StrikeSettings.strikes_collide: con músculos, choca de verdad), de cerca y al máximo del alcance, de costado y desde adentro. En pantalla, a qué
## velocidad pegó lo que pegó. Se graba con:
##   tools/godot_ventana.sh --resolution 960x540 --write-movie C:/carpeta/contacto.avi --fixed-fps 30 res://tests/arm_contact_movie.tscn

const AFTER := 1.0
const TIPS := [[ArmLoadout.Tip.HEAVY_FIST, "el puño pesado, directo"], [ArmLoadout.Tip.POLE, "el palo, mazazo"]]
const MODES := ["A. atraviesa", "B. choca"]
const RANGES := ["de cerca", "al máximo del alcance"]
const VIEWS := ["de costado", "desde adentro"]
## Cuánto entra lo más lejano del golpe en donde se le pega, al máximo del alcance (m); y de cerca, cuánto más cerca
## está la meca (en partes de lo que llega).
const DEEP := 0.4
const CLOSE := 0.45

var _boss: Brawler = null
var _mech: CageMech = null
var _eye: Camera3D = null
var _title: Label = null
var _speed: Label = null
var _view := 0


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 145.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.8, 0.82, 0.85)
	world.environment.ambient_light_energy = 0.6
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = _label(layer, Vector2(20, 10), 26)
	_speed = _label(layer, Vector2(20, 120), 34)
	var parent := Node3D.new()
	add_child(parent)
	BrawlerArchetype.thinking = false
	var root := BrawlerArchetype.new().build(0, parent)
	_boss = root.get_node("Luchador") as Brawler
	await _wait(0.5)
	for found in root.find_children("*", "Label3D", true, false):
		(found as Label3D).visible = false
	var theirs := (_boss.get_node("Cabeza") as BrawlerBrain).target as Mech
	theirs.put(Transform3D(Basis(), Vector3(300.0, 0.0, 300.0)))
	var number := 0
	for tip: Array in TIPS:
		var reach := await _build(tip[0])
		for mode in MODES.size():
			StrikeSettings.current.strikes_collide = mode == 1
			for near in RANGES.size():
				var back := reach * CLOSE if near == 0 else 0.0  # de cerca, más adelante
				_mech.put(Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 0.0, _hurt_front() + DEEP - reach + back)))
				await _wait(0.6)
				for view in VIEWS.size():
					_view = view
					number += 1
					_title.text = "%d. %s · %s · %s · %s" % [number, tip[1], MODES[mode], RANGES[near], VIEWS[view]]
					_speed.text = ""
					var arm := _mech.arms[1]
					while arm.punching != MechArm.Punch.NONE:
						await get_tree().physics_frame
					await _wait(0.3)
					_strike(arm, tip[0])
					while arm.punching != MechArm.Punch.NONE:
						if arm.last_hit != null:
							_speed.text = "pegó a %.0f m/s" % arm.last_hit_speed
						await get_tree().physics_frame
					if arm.last_hit == null:
						_speed.text = "no pegó"
					print("%-80s %s" % [_title.text, _speed.text])
					await _wait(AFTER)
	get_tree().quit()


func _strike(arm: MechArm, tip: ArmLoadout.Tip) -> void:
	if tip == ArmLoadout.Tip.POLE:
		arm.main_strike()
	else:
		arm.punch(MechArm.Punch.STRAIGHT)


## UNA MECA CON `tip` en el brazo derecho (con músculos, que atraviesa), lejos. Devuelve lo que llega su golpe hacia
## adelante (lo más lejano de lo que golpea, desde el medio de la meca, m), medido tirándolo al aire.
func _build(tip: ArmLoadout.Tip) -> float:
	if _mech != null:
		_mech.queue_free()
		await _wait(0.2)
	_mech = CageMech.new()
	_mech.scripted = true
	_mech.loadout = [ArmLoadout.of(ArmLoadout.Motion.POSE, ArmLoadout.Tip.CANNON, true),
		ArmLoadout.of(ArmLoadout.Motion.MUSCLE, tip, true)]
	_mech.position = Vector3(0.0, Mech.standing_height(Mech.Cabin.CAGE), -60.0)
	add_child(_mech)
	_mech.label.visible = false
	_mech.put(Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 0.0, -60.0)))
	await _wait(1.5)
	(_mech.cabin as CageCabin).evict(CageCabin.DRIVER)
	StrikeSettings.current.strikes_collide = false
	var arm := _mech.arms[1]
	var start := _mech.global_position.z
	var most := 0.0
	_strike(arm, tip)
	while arm.punching != MechArm.Punch.NONE:
		await get_tree().physics_frame
		for point in arm.tip.strike_points():
			most = maxf(most, point.z - start)
	print("%s: llega %.1f m adelante" % [tip, most])
	return most


## El frente de donde se le pega al jefe, del lado de la meca (z del mundo).
func _hurt_front() -> float:
	var holder := _boss.hurtbox.get_child(0) as CollisionShape3D
	return holder.global_position.z - (holder.shape as BoxShape3D).size.z * 0.5


func _process(delta: float) -> void:
	if _mech == null or not is_instance_valid(_mech):
		return
	var at := _mech.global_position
	if _view == 0:
		var middle := Vector3(0.0, at.y, (at.z + _hurt_front()) * 0.5)
		_eye.fov = 45.0
		_eye.global_position = middle + Vector3(-17.0, 2.0, -4.0)
		_eye.look_at(middle + Vector3(0, 0.5, 0), Vector3.UP)
	else:
		_eye.fov = 75.0
		_eye.global_transform = _mech.possess_camera(true, delta)


func _label(layer: CanvasLayer, at: Vector2, size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 10)
	layer.add_child(label)
	return label


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
