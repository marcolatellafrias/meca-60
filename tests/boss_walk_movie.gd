extends Node

## LOS JEFES CON PATAS CAMINANDO (con ventana, unos 20 segundos de video; 18/11/2026): dos armazones del Taller
## (BossFrame), uno de CUATRO patas (pisan las diagonales) y uno de DOS, con sus patas en el esqueleto común
## (BossLegs: MechSkeleton, la marcha común Gait y la IK común), hacen el mismo recorrido: arrancar, doblar andando,
## frenar, ir de costado, girar en el lugar, apurarse y frenar. Se los mueve desde afuera (como el Taller o una cabeza):
## las patas siguen solas. Una grilla en el piso cada 2 m para ver si los pies patinan. Imprime cuántos pasos dio cada
## uno, lo más que se corrió un pie apoyado y lo más que se separó una canilla de la punta de su muslo. Con --write-movie:
##   tools/godot_ventana.sh --resolution 960x540 --write-movie C:/carpeta/jefes.avi --fixed-fps 30 res://tests/boss_walk_movie.tscn

## El recorrido: [texto, s, adelante m/s, de costado m/s, giro °/s].
const ROUTE := [
	["quietos", 1.0, 0.0, 0.0, 0.0],
	["arrancan y andan (4 m/s)", 3.0, 4.0, 0.0, 0.0],
	["doblan andando", 3.0, 4.0, 0.0, 30.0],
	["frenan", 1.5, 0.0, 0.0, 0.0],
	["de costado", 2.5, 0.0, 3.0, 0.0],
	["giran en el lugar", 2.5, 0.0, 0.0, 45.0],
	["se apuran (8 m/s)", 2.5, 8.0, 0.0, 0.0],
	["frenan de golpe", 2.0, 0.0, 0.0, 0.0],
]

var _frames: Array[BossFrame] = []
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	_world()
	for spec: Array in [["cuatro", Vector3(0.0, 0.0, 18.0)], ["bipedo", Vector3(0.0, 0.0, -18.0)]]:
		var frame := BossFrame.new()
		frame.position = spec[1]
		add_child(frame)
		frame.build(BossRecipe.of(spec[0], "ancho", "puno", "visor"))
		_frames.append(frame)
	_eye = Camera3D.new()
	_eye.fov = 55.0
	add_child(_eye)
	_eye.make_current()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var yaw := 0.0
	var first := true
	var slip: Array[float] = [0.0, 0.0]
	var loose: Array[float] = [0.0, 0.0]
	for leg: Array in ROUTE:
		_title.text = leg[0]
		var clock := 0.0
		while clock < float(leg[1]):
			var delta := 1.0 / Engine.physics_ticks_per_second
			yaw += deg_to_rad(float(leg[4])) * delta
			var turn := Basis(Vector3.UP, yaw)
			var velocity := turn * Vector3(float(leg[3]), 0.0, -float(leg[2]))
			var middle := Vector3.ZERO
			var before := []
			for frame in _frames:
				frame.global_transform = Transform3D(turn.scaled(Vector3.ONE * BossSettings.current.scale),
					frame.global_position + velocity * delta)
				before.append([frame.walking.gait.feet.duplicate(), frame.walking.gait.swing_share.duplicate()])
				middle += frame.global_position / _frames.size()
			await get_tree().physics_frame
			for index in _frames.size():
				var gait := _frames[index].walking.gait
				var bones := _frames[index].walking.skeleton
				for foot in gait.feet.size():
					if before[index][1][foot] < 0.0 and gait.swing_share[foot] < 0.0:
						slip[index] = maxf(slip[index], (gait.feet[foot] - (before[index][0][foot] as Vector3)).length())
					var tip := bones.thighs[foot].global_transform * Vector3(0.0, bones.thighs[foot].capsule_dimensions.y, 0.0)
					loose[index] = maxf(loose[index], tip.distance_to(bones.shins[foot].global_position))
			middle += Vector3.UP * 6.0
			var wanted := middle + Vector3(48.0, 12.0, 26.0)
			_eye.global_position = wanted if first else _eye.global_position.lerp(wanted, 0.06)
			first = false
			_eye.look_at(middle, Vector3.UP)
			clock += delta
	for index in _frames.size():
		print("%s: %d pasos · un pie apoyado se corrió %.3f m · la canilla, a %.3f m de la punta del muslo" % [
			_frames[index].recipe.legs, _frames[index].walking.gait.steps_taken, slip[index], loose[index]])
	get_tree().quit()


func _world() -> void:
	var ground := Node3D.new()
	add_child(ground)
	Clay.box(ground, Vector3(600, 1, 600), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	for i in range(-100, 101):
		var tone := Color(0.6, 0.58, 0.55)
		Clay.box(ground, Vector3(0.08, 0.02, 400.0), Vector3(i * 2.0, 0.01, 0.0), tone)
		Clay.box(ground, Vector3(400.0, 0.02, 0.08), Vector3(0.0, 0.01, i * 2.0), tone)
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
	world.environment.ambient_light_energy = 0.6
	add_child(world)
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 16)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", Color.BLACK)
	layer.add_child(_title)
