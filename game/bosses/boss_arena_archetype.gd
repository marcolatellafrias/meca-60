class_name BossArenaArchetype
extends SeededArchetype

## LA ARENA DEL JEFE (13/11/2026) — TRABAJO EN CURSO: un redondel como el de la Arena de esquivar, con UNA MECA
## ENEMIGA en el medio que pelea de verdad (BossMech, con su cerebro) y la Meca discreta para poseer y pelearla a
## piñas. El usuario: «una arena distinta que sea para un boss que tenga vida arriba… la voy a poseer y voy a usar los
## controles directamente… quiero ver cómo se siente pelear».
## Hoy tiene UN JEFE DE PRUEBA (`test_boss`), para tener todo andando; los jefes de verdad se arman de a uno, a mano
## (el usuario: «después hacemos un boss solo entre los dos»).
##   · su vida, arriba de la pantalla (BossHealthBar), mientras uno está en la parcela.
##   · P: pelea o se queda quieta · K: el próximo ataque, ya · H: sacarle 25 de vida · U: subirse a la meca propia.
##   · R la vuelve a armar (con la vida llena).

const RADIUS := 95.0
const WALL_HEIGHT := 12.0
const WALL_THICK := 2.0
const SEGMENTS := 40
## A cuánto del medio nace la meca propia.
const START := 60.0


func _init() -> void:
	display_name = "Arena del jefe"


## EL JEFE DE PRUEBA: dos piernas, una sierra en una mano, un puño con ametralladora en el otro antebrazo y el ojo láser:
## lo que se salta (la onda al caer de un salto, la del puño en el piso, el láser), lo que se pasa agachado (la sierra
## tirada) y lo que se esquiva corriendo (la ráfaga).
static func test_boss() -> BossDesign:
	var made := BossDesign.new()
	made.title = "Jefe de prueba"
	made.torso_size = Vector3(11.0, 8.5, 10.0)
	made.legs = BossDesign.Legs.BIPED
	made.arms = [
		BossDesign.arm(-1.0, BossDesign.Hand.SAW),
		BossDesign.arm(1.0, BossDesign.Hand.FIST, BossDesign.Gear.GUN),
	]
	made.chest = BossDesign.Chest.LASER_EYE
	made.palette = 1
	return made


func max_footprint() -> Vector2:
	return Vector2.ONE * (RADIUS + WALL_THICK + 6.0) * 2.0


func far_height() -> float:
	return WALL_HEIGHT


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"TRABAJO EN CURSO: un jefe de prueba con vida; las piñas de la meca se la sacan",
		"se salta: la onda al caer de un salto, la del puño en el piso, el láser · agachado: la sierra tirada",
		"mirando la meca, O la posee · P pelea / quieta · K ataca ya · H sacarle vida · U subirse",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Arena del jefe"
	parent.add_child(root)
	var field := ProjectileField.new()
	field.name = "Proyectiles"
	root.add_child(field)
	_walls(root)
	var boss := BossMech.new()
	boss.design = test_boss()
	boss.field = field
	boss.show_label = false
	boss.position = Vector3(0.0, 0.0, 0.0)
	root.add_child(boss)
	boss.position.y = boss.knobs.hover_height + boss.size.y * 0.5
	var bar := BossHealthBar.new()
	bar.name = "Vida"
	bar.boss = boss
	bar.visible = false
	root.add_child(bar)
	var mech := Mech.new()
	mech.name = "Meca"
	mech.arms_kind = Mech.Arms.POSE
	mech.transform = Transform3D(Basis(), Vector3(0.0, BodySettings.current.hover_height + CabinGrid.HALF_HEIGHT, START))
	root.add_child(mech)
	return root


func _walls(root: Node3D) -> void:
	var walls := StaticBody3D.new()
	walls.name = "Muro"
	root.add_child(walls)
	var span := TAU * (RADIUS + WALL_THICK * 0.5) / SEGMENTS + 0.3
	for i in SEGMENTS:
		var angle := TAU * i / SEGMENTS
		var at := Vector3(sin(angle), 0.0, cos(angle)) * (RADIUS + WALL_THICK * 0.5) + Vector3.UP * WALL_HEIGHT * 0.5
		Clay.solid(walls, Vector3(span, WALL_HEIGHT, WALL_THICK), at, Clay.METAL.lightened(0.15), Basis(Vector3.UP, angle))
	var line := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = RADIUS - 1.2
	torus.outer_radius = RADIUS
	torus.rings = 96
	torus.ring_segments = 4
	line.mesh = torus
	line.scale = Vector3(1.0, 0.05, 1.0)
	line.position = Vector3.UP * 0.03
	line.material_override = Clay.material(Clay.DARK.lightened(0.2))
	root.add_child(line)


## LA BARRA DE VIDA, sólo mientras uno está en la parcela.
func entered(parcel: SandboxParcel, inside: bool) -> void:
	_parcel_seen = parcel
	for bar: BossHealthBar in parcel.find_children("*", "BossHealthBar", true, false):
		bar.visible = inside


var _parcel_seen: SandboxParcel = null


func keys() -> Array[SandboxKey]:
	return [
		SandboxKey.toggle(KEY_P, SandboxKey.Weight.MAIN, "el jefe pelea", _fighting,
			func(parcel: SandboxParcel, on: bool) -> void:
				_each(parcel, func(boss: BossMech) -> void:
					boss.brain.mode = BossBrain.Mode.FIGHT if on else BossBrain.Mode.STILL)),
		SandboxKey.action(KEY_K, SandboxKey.Weight.MAIN, "el próximo ataque, ya",
			func(parcel: SandboxParcel) -> void: _each(parcel, func(boss: BossMech) -> void: boss.brain.attack_now())),
		SandboxKey.action(KEY_H, SandboxKey.Weight.NORMAL, "sacarle 25 de vida",
			func(parcel: SandboxParcel) -> void: _each(parcel, func(boss: BossMech) -> void: boss.hurt(25.0))),
		SandboxKey.action(KEY_U, SandboxKey.Weight.NORMAL, "subirse a la meca (al piso del medio)",
			func(parcel: SandboxParcel) -> void:
				for mech: Mech in parcel.find_children("*", "Mech", true, false):
					mech.cabin.board()),
	]


func _fighting() -> bool:
	if not is_instance_valid(_parcel_seen):
		return true
	for boss: BossMech in _parcel_seen.find_children("*", "BossMech", true, false):
		return boss.brain.mode == BossBrain.Mode.FIGHT
	return true


static func _each(parcel: SandboxParcel, action: Callable) -> void:
	for boss: BossMech in parcel.find_children("*", "BossMech", true, false):
		action.call(boss)
