extends Node

## EL ESCUDO CONTRA EL LUCHADOR (sin ventana, alrededor de un minuto): cada ataque del jefe contra la meca quieta, sin
## escudo y con el escudo prendido (MechShield); de cada uno, cuánta vida le sacó. Con el escudo tiene que dar 0: el
## golpe se le pregunta una vez (BalanceBody.block_hit) y queda usado. --solo=piso, sólo los que lo tienen en el nombre;
## --ver, cuántas veces lo usó.
##   godot --headless --path . res://tests/boss_shield_check.tscn

const ACTS := {"embestida": BrawlerBrain.Act.CHARGE, "golpe al piso": BrawlerBrain.Act.SLAM,
	"piedra": BrawlerBrain.Act.THROW, "trompo": BrawlerBrain.Act.SPIN, "agarre": BrawlerBrain.Act.HOOK,
	"lanzallamas": BrawlerBrain.Act.FLAME}
const GAPS := {"embestida": 60.0, "golpe al piso": 50.0, "piedra": 60.0, "trompo": 30.0, "agarre": 45.0,
	"lanzallamas": 35.0}

var _boss: Brawler = null
var _brain: BrawlerBrain = null
var _mech: ToolMech = null
## Sólo los ataques que tienen esto en el nombre (--solo=piso).
var _only := ""


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var parent := Node3D.new()
	add_child(parent)
	BrawlerArchetype.thinking = true
	BrawlerSettings.current.rage.every = 0.0
	var root := BrawlerArchetype.new().build(0, parent)
	_boss = root.get_node("Luchador") as Brawler
	_brain = _boss.get_node("Cabeza") as BrawlerBrain
	_mech = _brain.target as ToolMech
	await _wait(0.5)
	_mech.scripted = true
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--solo="):
			_only = argument.trim_prefix("--solo=")
	for title: String in ACTS:
		if not _only.is_empty() and not title.contains(_only):
			continue
		var line := "%s:" % title
		for shielded: bool in [false, true]:
			line += " %s %.0f" % ["con escudo" if shielded else "sin escudo", await _try(ACTS[title], GAPS[title], shielded)]
		print(line)
	get_tree().quit()


## Un ataque desde `gap`; devuelve cuánta vida le sacó.
func _try(act: BrawlerBrain.Act, gap: float, shielded: bool) -> float:
	await _place(gap)
	_mech.shield.held = shielded
	await _wait(0.2)
	_brain.awake = true
	await get_tree().physics_frame
	_brain._begin(act)
	var uses := _brain.power(act).uses
	var clock := 0.0
	while clock < 12.0 and _brain.act == act:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		_mech.energy.level = 1.0
	await _wait(2.5)
	if OS.get_cmdline_user_args().has("--ver"):
		print("  %s: lo usó %d veces en %.1f s, el escudo %s" % [_brain.power(act).title(), _brain.power(act).uses - uses,
			clock, "prendido" if _mech.shield.on else "apagado"])
	_brain.awake = false
	_mech.shield.held = false
	await _wait(3.0)
	return BrawlerArchetype.MECH_HEALTH - Health.of(_mech).left


func _place(gap: float) -> void:
	_brain.awake = false
	for wave in (_brain.power(BrawlerBrain.Act.SLAM) as SlamPower).waves:
		if is_instance_valid(wave):
			wave.queue_free()
	(_brain.power(BrawlerBrain.Act.SLAM) as SlamPower).waves.clear()
	for rock in (_brain.power(BrawlerBrain.Act.THROW) as ThrowPower).rocks:
		if is_instance_valid(rock):
			rock.queue_free()
	(_brain.power(BrawlerBrain.Act.THROW) as ThrowPower).rocks.clear()
	await _wait(0.1)
	_boss.put(Transform3D(Basis(), Vector3(0.0, 0.0, gap * 0.5)))
	# Sus piezas sólidas llegan en el próximo paso, barriendo: la meca, después (si no, la lanzan).
	await _wait(0.05)
	_mech.put(Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, Mech.standing_height(), -gap * 0.5)))
	HitReaction.of(_mech).clear()
	var clock := 0.0
	while _mech.state != BalanceBody.State.STANDING and clock < 5.0:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
	Health.of(_mech).left = BrawlerArchetype.MECH_HEALTH
	_mech.energy.level = 1.0
	_mech.energy.stunned = 0.0
	await _wait(0.6)


func _wait(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second

