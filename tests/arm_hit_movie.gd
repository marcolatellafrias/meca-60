extends Node

## PEGARLE AL JEFE ATRAVESÁNDOLO (17/11/2026; el usuario: «que lo atraviese, pero que le pegue y mostrar que le pegó con
## alguna partícula… me prepares algunos videos con el primer approach solamente»): la meca jaula, con el brazo derecho
## con músculos que ATRAVIESA (StrikeSettings.strikes_collide apagado) y pega con lo que barre su punta (MechArm, «El golpe»),
## le tira al Luchador quieto las cuatro piñas, primero con el puño pesado y después con el palo, cada vez desde tres
## lados: de costado, desde atrás de la meca y desde adentro (donde va el que maneja). Imprime cuántas conectaron y cuánta
## vida le sacaron. Se graba con:
##   tools/godot_ventana.sh --resolution 960x540 --write-movie C:/carpeta/golpes.avi --fixed-fps 30 res://tests/arm_hit_movie.tscn

const PUNCH_TIME := 1.6
const KINDS := [MechArm.Punch.STRAIGHT, MechArm.Punch.HOOK, MechArm.Punch.UPPERCUT, MechArm.Punch.HAMMER]
const TIPS := [[ArmLoadout.Tip.HEAVY_FIST, "el puño pesado"], [ArmLoadout.Tip.POLE, "el palo"]]
const VIEWS := ["de costado", "desde atrás", "desde adentro"]
## Cuánto más allá del frente de donde se le pega llega el directo (m).
const DEEP := 1.2

var _boss: Brawler = null
var _mech: CageMech = null
var _eye: Camera3D = null
var _title: Label = null
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
	_title = Label.new()
	_title.position = Vector2(20, 10)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)
	var parent := Node3D.new()
	add_child(parent)
	BrawlerArchetype.thinking = false
	var root := BrawlerArchetype.new().build(0, parent)
	_boss = root.get_node("Luchador") as Brawler
	await _wait(0.5)
	# Sus carteles de lo que mide, apagados: de cerca tapan todo.
	for found in root.find_children("*", "Label3D", true, false):
		(found as Label3D).visible = false
	# La meca que trae el jefe, lejos: ésta es otra, con el brazo que se prueba.
	var theirs := (_boss.get_node("Cabeza") as BrawlerBrain).target as Mech
	theirs.put(Transform3D(Basis(), Vector3(300.0, 0.0, 300.0)))
	StrikeSettings.current.strikes_collide = false
	var number := 0
	for tip: Array in TIPS:
		await _build(tip[0])
		for view in VIEWS.size():
			_view = view
			for kind: MechArm.Punch in KINDS:
				number += 1
				_title.text = "%d. %s · %s · %s" % [number, tip[1], MechArm.NAMES[kind], VIEWS[view]]
				var before := Health.of(_boss).left
				var arm := _mech.arms[1]
				# La anterior, terminada: si no, ésta no sale.
				while arm.punching != MechArm.Punch.NONE:
					await get_tree().physics_frame
				arm.punch(kind)
				await _wait(PUNCH_TIME)
				print("%-42s conectó a %4.1f m/s (%s) · le sacó %.2f" % [_title.text, arm.last_hit_speed,
					arm.last_hit.name if arm.last_hit != null else "-", before - Health.of(_boss).left])
	get_tree().quit()


## UNA MECA CON `tip` en el brazo derecho (con músculos, que atraviesa), enfrente del jefe: tan cerca que el puño del
## directo llega `DEEP` m más allá del frente de donde se le pega.
func _build(tip: ArmLoadout.Tip) -> void:
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
	# Lo lejos que llega el directo, adelante de la meca (lejos del jefe, sin pegarle a nada).
	var arm := _mech.arms[1]
	var start := _mech.global_position.z
	var most := 0.0
	arm.punch(MechArm.Punch.STRAIGHT)
	while arm.punching != MechArm.Punch.NONE:
		await get_tree().physics_frame
		most = maxf(most, arm.tip.strike_points()[0].z - start)
	var front := _hurt_front()
	_mech.put(Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 0.0, front + DEEP - most)))
	print("%s: el puño del directo llega %.1f m adelante; el frente de donde se le pega, a z %.1f" % [tip, most, front])
	await _wait(1.0)


## El frente de donde se le pega al jefe, del lado de la meca (z del mundo).
func _hurt_front() -> float:
	var holder := _boss.hurtbox.get_child(0) as CollisionShape3D
	var size := (holder.shape as BoxShape3D).size
	return holder.global_position.z - size.z * 0.5


func _process(_delta: float) -> void:
	if _mech == null or not is_instance_valid(_mech):
		return
	var at := _mech.global_position
	var boss := Vector3(0.0, at.y, _hurt_front())
	match _view:
		0:
			var middle := (at + boss) * 0.5
			_eye.fov = 45.0
			_eye.global_position = middle + Vector3(-17.0, 2.0, -6.0)
			_eye.look_at(middle + Vector3(0, 0.5, 0), Vector3.UP)
		1:
			_eye.fov = 60.0
			_eye.global_position = at + Vector3(-3.0, 4.0, -9.0)
			_eye.look_at(boss + Vector3(0, 1.0, 0), Vector3.UP)
		2:
			_eye.fov = 75.0
			_eye.global_transform = _mech.possess_camera(true, _delta)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
