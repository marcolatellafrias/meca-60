extends Node3D

## EL JEFE POR LA RED, CON DOS INSTANCIAS (sin ventana, unos 30 segundos; plan de la partida en red, paso 8):
##   godot --headless --path . res://tests/boss_net_check.tscn --host-local   (el host: simula al jefe)
##   godot --headless --path . res://tests/boss_net_check.tscn --join-local   (el otro: maneja la meca)
## Las dos arman la parcela del Luchador. EL OTRO toma la meca (como al poseerla) y la deja quieta; el jefe, que piensa
## sólo en el host, la ataca. A los 14 s las dos dicen lo que ven: dónde está el jefe, su pose, dónde está la meca,
## cuánta vida le queda y cuántas veces cayó (los golpes los decide el host; el empujón, la máquina del dueño). Después
## EL OTRO le pega al jefe hasta matarlo (el golpe se le pide al host) y las dos dicen si se murió y en cuántos pedazos.
## LO QUE SE VE DE SUS ATAQUES: durante la pelea, cada máquina cuenta cuántos efectos distintos vio de cada tipo (las
## zonas, la piedra, el fuego, la onda, la mano, las bombas): tienen que dar lo mismo en las dos.

var _host := false
var _boss: Brawler = null
var _mech: Mech = null


func _enter_tree() -> void:
	add_to_group("net_world")


func _ready() -> void:
	SessionManager.world_ready()
	_host = OS.get_cmdline_args().has("--host-local")
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var parent := Node3D.new()
	parent.name = "Parcela"
	add_child(parent)
	BrawlerSettings.current.rage.every = 0.0
	var root := BrawlerArchetype.new().build(0, parent)
	_boss = root.get_node("Luchador") as Brawler
	await get_tree().create_timer(4.0).timeout
	_mech = (_boss.get_node("Cabeza") as BrawlerBrain).target as Mech
	_mech.scripted = true
	if not _host:
		_mech.net.take_control()
	var seen := {}
	var clock := 0.0
	# Uno por uno, para verlos todos: la piedra, el lanzallamas, el golpe al piso y las bombas (los elige el host).
	var acts := [BrawlerBrain.Act.THROW, BrawlerBrain.Act.FLAME, BrawlerBrain.Act.SLAM, BrawlerBrain.Act.BOMB]
	while clock < 32.0:
		BrawlerBrain.moves = int(acts[mini(int(clock / 8.0), acts.size() - 1)]) - 1
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		for node in _boss.get_parent().get_children():
			for kind: Script in [BossZone, BrawlerRock, BrawlerFlame, BrawlerWave, BrawlerHook, BossShot]:
				if is_instance_of(node, kind):
					var key := str(kind.get_global_name())
					if not seen.has(key):
						seen[key] = {}
					(seen[key] as Dictionary)[node.get_instance_id()] = true
	BrawlerBrain.moves = -1
	var counts := PackedStringArray()
	for key: String in seen:
		counts.append("%s %d" % [key, (seen[key] as Dictionary).size()])
	print("%s EFECTOS: %s" % ["HOST" if _host else "CLIENTE", ", ".join(counts)])
	_report("PELEA")
	if not _host:
		Health.of(_boss).hurt(10000.0, "prueba", Vector3(0.0, 4.0, 12.0))
	# El host espera más: el otro arrancó después y pega después.
	await get_tree().create_timer(8.0 if _host else 3.0).timeout
	_report("MUERTE")
	await get_tree().create_timer(3.0 if _host else 1.0).timeout
	get_tree().quit()


func _report(when: String) -> void:
	var who := "HOST" if _host else "CLIENTE"
	var mech_health := Health.of(_mech)
	var boss_health := Health.of(_boss)
	print("%s %s: jefe en %s, pose %s · meca en %s, vida %.0f, caídas %d, dueño %d · jefe vida %.0f · pedazos %d" % [
		who, when, _boss.global_position.snapped(Vector3.ONE * 0.1), Brawler.POSE_NAMES[_boss.pose],
		_mech.mover.global_position.snapped(Vector3.ONE * 0.1), mech_health.left if mech_health != null else -1.0,
		_mech.falls, _mech.net.authority, boss_health.left if boss_health != null else -1.0,
		get_tree().get_nodes_in_group(PartsRagdoll.GROUP).size()])
