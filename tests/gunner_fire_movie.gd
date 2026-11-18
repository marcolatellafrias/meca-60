extends Node

## LAS ARMAS DEL ARTILLERO, DISPARANDO (18/11/2026; ver GunnerWeapons): la meca jaula de 3 frente al Luchador quieto, a
## `GAP` m; la torreta apunta al jefe y se aprietan los botones como lo haría el artillero: la minigun mantenida, la
## recarga con ritmo bien hecha, la sobrecarga hasta trabarse, enfriar; los misiles uno, la salva, uno guiado y, fijado
## el jefe, uno que lo persigue. Imprime cuánta vida le sacó cada cosa. Mitad de afuera, mitad desde los ojos. Se graba:
##   tools/godot_ventana.sh --resolution 960x540 --write-movie C:/carpeta/disparos.avi --fixed-fps 30 res://tests/gunner_fire_movie.tscn

const GAP := 45.0

var _boss: Brawler = null
var _mech: CageMech = null
var _turret: GunnerTurret = null
var _eye: Camera3D = null
var _title: Label = null
var _inside := false


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
	world.environment.ambient_light_energy = 0.6
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
	var parent := Node3D.new()
	add_child(parent)
	BrawlerArchetype.thinking = false
	var root := BrawlerArchetype.new().build(0, parent)
	_boss = root.get_node("Luchador") as Brawler
	await _wait(1.0)
	_mech = (_boss.get_node("Cabeza") as BrawlerBrain).target as CageMech
	_mech.scripted = true
	_mech.label.visible = false
	for found in root.find_children("*", "Label3D", true, false):
		if not (found as Node).get_parent() is StaticBody3D:
			(found as Label3D).visible = false
	_boss.put(Transform3D(Basis(), Vector3.ZERO))
	_mech.put(Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 0.0, -GAP)))
	await _wait(1.5)
	_turret = (_mech.cabin as CageCabin).turret
	var w := _turret.weapons
	await _stage("minigun, mantenida 2 s", func() -> void:
		w.trigger(true)
		await _wait(2.0)
		w.trigger(false))
	await _stage("recargar con ritmo: apretar en la zona", func() -> void:
		w.press("minigun")
		while w.reloading >= 0 and w.needle < (GunnerWeapons.ZONE.x + GunnerWeapons.ZONE.y) * 0.5:
			await get_tree().physics_frame
		w.press("minigun")
		print("  recargada: %d balas, fuerza ×%.1f" % [w.belt, w.strength[GunnerWeapons.Weapon.MINIGUN]]))
	_inside = true
	await _stage("sobrecarga, mantenida hasta trabarse", func() -> void:
		w.press("sobrecarga")
		w.trigger(true)
		var waited := 0.0
		while not w.jammed and waited < 6.0:
			await get_tree().physics_frame
			waited += get_physics_process_delta_time()
		w.trigger(false)
		print("  trabada: %s, calor %.2f" % [w.jammed, w.heat]))
	await _stage("enfriar", func() -> void:
		w.press("enfriar")
		await _wait(0.6))
	_inside = false
	await _stage("misiles: uno", func() -> void:
		w.press("misiles")
		w.trigger(true)
		w.trigger(false)
		await _wait(1.8))
	await _stage("salva: los que quedan", func() -> void:
		w.press("salva")
		await _wait(2.5))
	await _stage("recargar los misiles (sin apretar en la zona)", func() -> void:
		w.press("misiles")
		while w.reloading >= 0:
			await get_tree().physics_frame)
	await _stage("guiado: uno que va adonde apunta la torreta, que gira", func() -> void:
		w.press("guiado")
		w.trigger(true)
		w.trigger(false)
		var front := _mech.global_basis * Vector3.FORWARD
		var yaw := atan2(-front.x, -front.z)
		for k in 40:
			_turret.aim(yaw + deg_to_rad(12.0) * sin(k * 0.15), 0.05)
			await get_tree().physics_frame
		await _wait(1.5))
	await _stage("fijar el jefe, y uno que lo persigue", func() -> void:
		var front := _mech.global_basis * Vector3.FORWARD
		var yaw := atan2(-front.x, -front.z)
		for k in 30:
			_turret.aim(yaw, 0.12)
			await get_tree().physics_frame
		w.press("fijar")
		print("  fijado: %s" % (w.locked.name if w.locked != null else "nada"))
		for k in 30:
			_turret.aim(yaw + deg_to_rad(35.0), 0.1)
			await get_tree().physics_frame
		w.trigger(true)
		w.trigger(false)
		await _wait(2.0))
	print("SONIDOS: ", MechSounds.heard)
	get_tree().quit()


## UN PASO del guion, con su nombre en pantalla; imprime cuánta vida le sacó.
func _stage(name_of: String, act: Callable) -> void:
	_title.text = name_of
	var before := Health.of(_boss).left
	await act.call()
	print("%-55s le sacó %.1f" % [name_of, before - Health.of(_boss).left])


func _physics_process(_delta: float) -> void:
	if _turret == null:
		return
	var seat := _turret.frame.global_transform
	if _inside:
		var eye := seat * Vector3(0.0, 1.15, 0.02)
		_eye.fov = 75.0
		_eye.global_position = eye
		_eye.look_at(eye + seat.basis * Vector3(0.0, -0.25, -3.0), Vector3.UP)
	else:
		var at := _turret.global_position + Vector3(0.0, 1.0, 0.0)
		_eye.fov = 55.0
		_eye.global_position = at + _mech.global_basis * Vector3(4.5, 2.2, 6.0)
		_eye.look_at(at + _mech.global_basis * Vector3(0.0, 0.0, -14.0), Vector3.UP)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
