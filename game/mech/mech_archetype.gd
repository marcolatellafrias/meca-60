class_name MechArchetype
extends SeededArchetype

## LA PARCELA DE LA MECA (ver Mech): la meca en el medio y, adelante, UNA MECA DE PRÁCTICA sin brazos para pegarle. DOS
## FILAS LA USAN, una por camino (`arms`): la Meca discreta, con brazos de pose, y la Meca física, con brazos de
## músculos. Mirándola, O la posee; U sube al jugador; J tira una bola y K pasa por los cuatro tiros; F1 sus perillas,
## N/M pegarle arriba, L el ascensor; R la vuelve a poner.

## Grande: corre y salta.
const FOOTPRINT := 120.0
## A cuánto de la meca va la de práctica, adelante de ella (m, de centro a centro).
const SPARRING := 16.0
## LOS CUATRO TIROS (el usuario: «lento que no voltee, lento que voltee, rápido que no voltee y rápido que voltee»): la
## bola va lenta o rápida (m/s) y el golpe es chico o grande (m/s que le cambiaría la velocidad a la caja suelta).
const SLOW := 30.0
const FAST := 100.0
const SMALL := 5.0
const BIG := 14.0

## El camino: qué brazos lleva. Y si se mueve cinemática (ver KinematicMover).
var arms := Mech.Arms.POSE
var kinematic := false


func _init(arms_kind := Mech.Arms.POSE, moves_kinematic := false) -> void:
	arms = arms_kind
	kinematic = moves_kinematic
	display_name = "Meca cinemática" if kinematic else Mech.NAMES[arms]


func max_footprint() -> Vector2:
	return Vector2(FOOTPRINT, FOOTPRINT)


func describe(_seed_value: int) -> PackedStringArray:
	if kinematic:
		return PackedStringArray([
			"la mueve el controlador de personaje del motor: contra lo fijo, un cilindro; sus pies patean y achatan",
			"movimiento discreto: Shift dash (con dirección) · espacio salta (y en el aire vuela) · Ctrl se agacha",
			"mirándola, O la posee (T cambia la vista) · U subirse",
		])
	return PackedStringArray([
		"una caja física que es un péndulo sobre su apoyo: una piña la saca de arriba de los pies, una pared no",
		"brazos %s" % ("físicos: chocan y se traban" if arms == Mech.Arms.MUSCLE else "discretos: atraviesan, y al conectar empujan"),
		"mirándola, O la posee (T cambia la vista) · U subirse (adentro y por afuera se camina)",
		"Shift corre · Ctrl se agacha · espacio carga el salto y, en el aire, propulsor",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Meca"
	parent.add_child(root)
	var standing := Mech.standing_height()
	# Nace donde va parada, mirando hacia donde uno llega (−X); la de práctica, adelante, mirándola.
	var mech := Mech.new()
	mech.arms_kind = arms
	mech.kinematic = kinematic
	mech.transform = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.0, standing, 0.0))
	root.add_child(mech)
	var target := Mech.new()
	target.arms_kind = Mech.Arms.NONE
	target.transform = Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-SPARRING, standing, 0.0))
	root.add_child(target)
	return root


## La bola, subirse, y pegarle arriba suave o fuerte y el ascensor (eran el panel F2, MechKnockPanel: acciones de
## prueba, van en el panel chico; el usuario, 13/11/2026: «empuje liviano, empuje fuerte… deberían ir en panel chico»).
func keys() -> Array[SandboxKey]:
	var out := TestBall.keys(self)
	out.append(SandboxKey.action(KEY_U, SandboxKey.Weight.MAIN, "subirse a la meca (adentro)",
		func(parcel: SandboxParcel) -> void:
			for mech: Mech in parcel.find_children("*", "Mech", true, false):
				if mech.arms_kind != Mech.Arms.NONE and mech.cabin != null:
					mech.cabin.board()))
	out.append_array(MechArchetype.knock_keys())
	return out


## PEGARLE Y EL ASCENSOR, para toda parcela con mecas (la Arena de esquivar también las usa).
static func knock_keys() -> Array[SandboxKey]:
	return [
		SandboxKey.action(KEY_N, SandboxKey.Weight.NORMAL, "pegarle suave",
			func(parcel: SandboxParcel) -> void: _each(parcel, func(mech: Mech) -> void: mech.knock(false))),
		SandboxKey.action(KEY_M, SandboxKey.Weight.NORMAL, "pegarle fuerte",
			func(parcel: SandboxParcel) -> void: _each(parcel, func(mech: Mech) -> void: mech.knock(true))),
		SandboxKey.action(KEY_Y, SandboxKey.Weight.NORMAL, "ascensor: subir una parada",
			func(parcel: SandboxParcel) -> void: _each(parcel, func(mech: Mech) -> void: if mech.cabin != null: mech.cabin.lift.up())),
		SandboxKey.action(KEY_H, SandboxKey.Weight.NORMAL, "ascensor: bajar una parada",
			func(parcel: SandboxParcel) -> void: _each(parcel, func(mech: Mech) -> void: if mech.cabin != null: mech.cabin.lift.lower())),
	]


static func _each(parcel: SandboxParcel, action: Callable) -> void:
	for mech: Mech in parcel.find_children("*", "Mech", true, false):
		action.call(mech)


func ball_shots() -> Array[Dictionary]:
	return [
		TestBall.shot("lenta, no la voltea", TestBall.push_for(Mech.MASS, SMALL, SLOW), SLOW),
		TestBall.shot("lenta, la voltea", TestBall.push_for(Mech.MASS, BIG, SLOW), SLOW),
		TestBall.shot("rápida, no la voltea", TestBall.push_for(Mech.MASS, SMALL, FAST), FAST),
		TestBall.shot("rápida, la voltea", TestBall.push_for(Mech.MASS, BIG, FAST), FAST),
	]
