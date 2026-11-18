extends Node

## EL TALADRO Y LA SIERRA DESDE LOS MANDOS DE LA JAULA (18/11/2026; ver CageBoards._arm_use): la meca jaula con el
## taladro a la izquierda (discreto) y la sierra a la derecha (con músculos), frente a dos pilas de cajas. Se agarra cada
## mando y se mantiene el clic: gira y gasta energía; al soltar, el directo. Imprime lo que giraba y cuánto se movieron
## las cajas. Se graba:
##   tools/godot_ventana.sh --resolution 960x540 --write-movie C:/carpeta/giran.avi --fixed-fps 30 res://tests/spin_tips_movie.tscn

const CRATE := 0.9
const GAP := 5.0

var _mech: CageMech = null
var _eye: Camera3D = null
var _title: Label = null
var _crates: Array[RigidBody3D] = []


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 205.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.8, 0.82, 0.85)
	world.environment.ambient_light_energy = 0.7
	add_child(world)
	_eye = Camera3D.new()
	_eye.near = 0.02
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 10)
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)
	_mech = CageMech.new()
	_mech.loadout = [ArmLoadout.of(ArmLoadout.Motion.POSE, ArmLoadout.Tip.DRILL, true),
		ArmLoadout.of(ArmLoadout.Motion.MUSCLE, ArmLoadout.Tip.SAW, true)]
	_mech.position = Vector3(0.0, Mech.standing_height(_mech.cabin_shape), 0.0)
	add_child(_mech)
	for side in [-1.0, 1.0]:
		for i in 3:
			var crate := RigidBody3D.new()
			crate.mass = 80.0
			Clay.solid(crate, Vector3.ONE * CRATE, Vector3.ZERO, Clay.METAL.lerp(Color(0.7, 0.5, 0.3), 0.6))
			crate.position = Vector3(side * 1.1, CRATE * 0.5 + i * CRATE, -GAP)
			add_child(crate)
			_crates.append(crate)
	await _wait(1.5)
	_mech.label.visible = false
	var cabin := _mech.cabin as CageCabin
	for seat in CageCabin.SEAT_NAMES.size():
		cabin.evict(seat)
	await _wait(0.5)
	var drill_arm := FoldingArmArchetype.arm_of(CageBoards.piece_of(cabin, "brazo izquierdo"))
	var saw_arm := FoldingArmArchetype.arm_of(CageBoards.piece_of(cabin, "brazo derecho"))
	await _use("taladro: mantener el clic", "soltar: el directo", drill_arm, -1.0)
	await _use("sierra: mantener el clic", "soltar: el directo", saw_arm, 1.0)
	get_tree().quit()


## Agarra el mando, mantiene 1,6 s y suelta; imprime lo que giraba y lo que se movieron las cajas de ese lado.
func _use(holding: String, letting: String, arm: Node, side: float) -> void:
	var before := _spots()
	arm.enter_mode()
	_title.text = holding
	arm.use.call(true)
	await _wait(1.6)
	var tip: SpinTip = null
	for found in _mech.arms:
		if found.tip is SpinTip and signf(_mech.to_local(found.anchor.global_transform * found.shoulder_local).x) == side:
			tip = found.tip
	var spin := tip.spin if tip != null else -1.0
	_title.text = letting
	arm.use.call(false)
	await _wait(1.6)
	arm.exit_mode()
	var after := _spots()
	var moved := 0.0
	for i in _crates.size():
		moved = maxf(moved, (after[i] - before[i]).length())
	print("%-28s giraba %.2f · energía %.2f · la caja que más se movió: %.2f m" % [holding, spin, _mech.energy.level,
		moved])


func _spots() -> Array[Vector3]:
	var spots: Array[Vector3] = []
	for crate in _crates:
		spots.append(crate.global_position)
	return spots


func _physics_process(_delta: float) -> void:
	if _mech == null:
		return
	var at := _mech.global_position
	_eye.fov = 55.0
	_eye.global_position = at + _mech.global_basis * Vector3(-5.5, 3.0, -7.5)
	_eye.look_at(at + _mech.global_basis * Vector3(0.0, -0.3, -2.0), Vector3.UP)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
