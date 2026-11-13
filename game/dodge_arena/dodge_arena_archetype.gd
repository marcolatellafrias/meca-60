class_name DodgeArenaArchetype
extends SeededArchetype

## LA ARENA DE ESQUIVAR (13/11/2026): un redondel vacío con una torre al medio que le tira misiles de mortero a la meca
## (ver MissileTurret), para probar con algo real cómo se siente moverla: caminar, correr, saltar y, cuando estén, los
## dashes. El usuario: «una parcela que sea como una especie de arena circular, sin nada, y que al medio tenga un boss
## que sea nada… después podemos agregarle otros movimientos para esquivar».
##   · EL REDONDEL: una línea en el piso y un muro alrededor, más alto que donde empieza la caja de la meca (lo único que
##     choca: un muro bajo le pasaría por abajo).
##   · LA MECA DISCRETA, adentro, mirando a la torre. Mirándola, O la posee.
##   · K elige el ataque de la torre (ver MissileTurret); P la prende y la apaga; U sube al jugador a la meca.

## El radio del redondel (m), el alto del muro y cuántos tramos tiene.
const RADIUS := 95.0
const WALL_HEIGHT := 12.0
const WALL_THICK := 2.0
const SEGMENTS := 40
## A cuánto de la torre nace la meca.
const START := 55.0


func _init() -> void:
	display_name = "Arena de esquivar"


func max_footprint() -> Vector2:
	return Vector2.ONE * (RADIUS + WALL_THICK + 6.0) * 2.0


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"TRABAJO EN CURSO: una torre al medio tira ataques de área; la marca del piso se llena justo antes de pegar",
		"K elige el ataque: lluvia, círculo gigante, dona, ondas, lanza, alfombra, pared que cruza, o todos de a uno",
		"mirando la meca, O la posee · P prende y apaga la torre · U subirse",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Arena"
	parent.add_child(root)
	var field := ProjectileField.new()
	field.name = "Proyectiles"
	root.add_child(field)
	var turret := MissileTurret.new()
	turret.name = "Torre"
	turret.field = field
	root.add_child(turret)
	var walls := StaticBody3D.new()
	walls.name = "Muro"
	root.add_child(walls)
	var span := TAU * (RADIUS + WALL_THICK * 0.5) / SEGMENTS + 0.3
	for i in SEGMENTS:
		var angle := TAU * i / SEGMENTS
		var at := Vector3(sin(angle), 0.0, cos(angle)) * (RADIUS + WALL_THICK * 0.5) + Vector3.UP * WALL_HEIGHT * 0.5
		var turn := Basis(Vector3.UP, angle)
		Clay.solid(walls, Vector3(span, WALL_HEIGHT, WALL_THICK), at, Clay.METAL.lightened(0.15), turn)
	# La línea del redondel, en el piso.
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
	var mech := Mech.new()
	mech.name = "Meca"
	mech.arms_kind = Mech.Arms.POSE
	mech.transform = Transform3D(Basis(), Vector3(0.0, BodySettings.current.hover_height + CabinGrid.HALF_HEIGHT, START))
	root.add_child(mech)
	return root


## La torre (prenderla y qué ataque tira: era el panel F3, AttackPanel; el usuario había pedido «un toggle de panel
## chico»), subirse, y pegarle y el ascensor como en las otras filas de la meca.
func keys() -> Array[SandboxKey]:
	var out: Array[SandboxKey] = [
		SandboxKey.toggle(KEY_P, SandboxKey.Weight.MAIN, "la torre tira", _turret_firing,
			func(parcel: SandboxParcel, on: bool) -> void:
				for turret in _turrets(parcel):
					turret.firing = on),
		SandboxKey.cycle(KEY_K, SandboxKey.Weight.MAIN, "ataque", MissileTurret.NAMES, _turret_attack,
			func(parcel: SandboxParcel, index: int) -> void:
				for turret in _turrets(parcel):
					turret.choose(index as MissileTurret.Attack)),
		SandboxKey.action(KEY_U, SandboxKey.Weight.NORMAL, "subirse a la meca (al piso del medio)",
			func(parcel: SandboxParcel) -> void:
				for mech: Mech in parcel.find_children("*", "Mech", true, false):
					mech.cabin.board()),
	]
	out.append_array(MechArchetype.knock_keys())
	return out


var _parcel_seen: SandboxParcel = null


func entered(parcel: SandboxParcel, inside: bool) -> void:
	if inside:
		_parcel_seen = parcel


func _turrets(parcel: SandboxParcel) -> Array[MissileTurret]:
	var out: Array[MissileTurret] = []
	for turret: MissileTurret in parcel.find_children("*", "MissileTurret", true, false):
		out.append(turret)
	return out


func _turret_firing() -> bool:
	var turrets := _turrets(_parcel_seen) if is_instance_valid(_parcel_seen) else ([] as Array[MissileTurret])
	return not turrets.is_empty() and turrets[0].firing


func _turret_attack() -> int:
	var turrets := _turrets(_parcel_seen) if is_instance_valid(_parcel_seen) else ([] as Array[MissileTurret])
	return int(turrets[0].attack) if not turrets.is_empty() else 0
