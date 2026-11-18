class_name CageMechArchetype
extends MechArchetype

## LA PARCELA DE LA MECA JAULA (CageMech), la primera del sandbox (16/11/2026): la meca, la de práctica adelante para
## pegarle (una jaula sin brazos) y una pila de cajas chicas a un costado, a su medida. Las teclas y la bola, las de toda
## parcela con la meca (MechArchetype).
## *Hasta el 17/11/2026 heredaba de la parcela de la Meca de tres (ToolMechArchetype), borrada con la meca grande; de ahí
## venían las cajas.*

## EL NOMBRE DE SU FILA: de ahí sale el equipo guardado de sus brazos (Mech.equipment, MechLoadout), también para las
## mecas jaula de otras parcelas (el Mapa de pelea, la Base, el Luchador de orugas).
const ROW := "Meca jaula"
const CAGE_TARGET := 18.0
## Las cajas para tirarles: cuántas, su lado (m) y lo que pesa cada una (kg).
const CRATES := 9
const SMALL_CRATE := 0.63
const SMALL_CRATE_MASS := 300.0


func _init() -> void:
	display_name = ROW


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"la meca jaula: abajo el que maneja, arriba el de los brazos, atrás el artillero; cañón a la izquierda, palo a la derecha",
		"mirándola, O la posee (T cambia la vista): sus controles, abajo a la derecha · F1 su forma de moverse",
		"adelante, la de práctica; a la derecha, cajas para tirarles · U a la cubierta · L la grilla de los tableros",
	])


## Las de toda meca (MechArchetype.keys), LA GRILLA DE LOS TABLEROS (ver CageBoards: para ubicar piezas, no de la meca)
## y PARA CUÁNTOS JUGADORES (CageShape.crew; el usuario, 18/11/2026, por Armas: una sola tecla que pase por las tres, sin
## guardarse): rearma las mecas (Mech.rebuild_all), como el F2.
func keys() -> Array[SandboxKey]:
	var out := super()
	out.append(SandboxKey.cycle(KEY_P, SandboxKey.Weight.NORMAL, "para cuántos",
		["1 jugador", "2 jugadores", "3 jugadores"], func() -> int: return CageShape.crew,
		func(parcel: SandboxParcel, crew: int) -> void:
			CageShape.crew = crew
			Mech.rebuild_all(parcel.get_tree())))
	out.append(SandboxKey.toggle(KEY_L, SandboxKey.Weight.NORMAL, "la grilla de los tableros",
		func() -> bool: return CageBoards.show_grid,
		func(parcel: SandboxParcel, on: bool) -> void: CageBoards.set_grid_visible(parcel.get_tree(), on)))
	return out


func default_loadout() -> Array[ArmLoadout]:
	return CageMech.default_arms()


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = display_name
	parent.add_child(root)
	var mech := CageMech.new()
	mech.equipment = display_name
	mech.transform = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.0, Mech.standing_height(mech.cabin_shape), 0.0))
	root.add_child(mech)
	# LA DE PRÁCTICA: una meca sin brazos (con la cabina jaula, como toda meca).
	var target := Mech.new()
	target.arms_kind = Mech.Arms.NONE
	target.transform = Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-CAGE_TARGET, Mech.standing_height(), 0.0))
	root.add_child(target)
	# Las cajas, en una pila de tres por tres, adelante a la derecha de la meca (que mira hacia −X).
	for i in CRATES:
		var crate := RigidBody3D.new()
		crate.mass = SMALL_CRATE_MASS
		Clay.solid(crate, Vector3.ONE * SMALL_CRATE, Vector3.ZERO, Clay.METAL.lerp(Color(0.7, 0.5, 0.3), 0.6))
		crate.position = Vector3(-8.0 + (i % 3) * (SMALL_CRATE + 0.05), SMALL_CRATE * 0.5 + (i / 3) * SMALL_CRATE, -4.0)
		root.add_child(crate)
	return root
