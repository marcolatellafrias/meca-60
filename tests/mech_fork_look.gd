extends Node3D

## LOS DOS CAMINOS DE LA MECA, PARA MIRAR (unos 25 segundos): la parcela de la Meca discreta y la de la Meca física, lado
## a lado, cada una con su cubo para pegarle. La discreta le tira un directo y un gancho al cubo: imprime a qué velocidad
## conectó y cuánto lo inclinó. Con ventana, capturas.
##   tools/godot_ventana.sh res://tests/mech_fork_look.tscn -- --salida=C:/carpeta

const APART := 70.0

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 14)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(900, 1, 900), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(900, 1, 900), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, 35.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.82, 0.84, 0.87)
	world.environment.ambient_light_energy = 0.8
	add_child(world)
	var mechs: Array[Mech] = []
	var targets: Array[Mech] = []
	for index in 2:
		var holder := Node3D.new()
		holder.position = Vector3(0.0, 0.0, index * APART)
		add_child(holder)
		var root := MechArchetype.new(Mech.Arms.MUSCLE if index == 1 else Mech.Arms.POSE).build(0, holder)
		for cube: Mech in root.find_children("*", "Mech", true, false):
			cube.label.visible = false
			if cube.arms_kind != Mech.Arms.NONE:
				mechs.append(cube)
			else:
				targets.append(cube)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	await get_tree().create_timer(3.0).timeout
	for index in 2:
		var at := mechs[index].global_position
		_eye.global_position = at + Vector3(-8.0, 2.0, 36.0)
		_eye.look_at(at + Vector3(-8.0, -2.0, 0.0))
		await _shot("%s, con su cubo para pegarle" % mechs[index].name, "%d_fila" % (index + 1))
	# LA DISCRETA LE PEGA A SU CUBO.
	var mech := mechs[0]
	var target := targets[0]
	var at := mech.global_position
	_eye.global_position = at + Vector3(-8.0, 2.0, 30.0)
	_eye.look_at(at + Vector3(-8.0, -2.0, 0.0))
	for kind: int in [MechArm.Punch.STRAIGHT, MechArm.Punch.HOOK]:
		var arm := mech.arms[1] as PoseArm
		arm.punch(kind as MechArm.Punch)
		var most := 0.0
		var shot := false
		for step in 600:
			await get_tree().physics_frame
			most = maxf(most, rad_to_deg(target.global_basis.y.angle_to(Vector3.UP)))
			if not shot and arm.stage() == MechArm.Stage.HOLD:
				shot = true
				await _shot("Discreta: %s" % MechArm.NAMES[kind], "3_%d_pega" % kind)
		print("DISCRETA, %s: conectó a %.0f m/s con %s · el cubo se inclinó hasta %.0f° · estado %d · la meca se inclinó %.1f°" % [
			MechArm.NAMES[kind], arm.last_hit_speed, arm.last_hit.name if arm.last_hit != null else "nada", most, target.state,
			rad_to_deg(mech.global_basis.y.angle_to(Vector3.UP))])
		await _shot("Discreta, después del %s" % MechArm.NAMES[kind], "4_%d_despues" % kind)
		await get_tree().create_timer(2.0).timeout
	get_tree().quit()


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
