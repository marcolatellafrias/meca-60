class_name MechArchetype
extends SeededArchetype

## LA PARCELA DE LA MECA (ver Mech): la meca en el medio y, adelante, UNA MECA DE PRÁCTICA sin brazos para pegarle. DOS
## FILAS LA USAN, una por camino (`arms`): la Meca discreta, con brazos de pose, y la Meca física, con brazos de
## músculos. Mirándola, O la posee; U sube al jugador; J tira una bola y K pasa por los cuatro tiros; F1 sus perillas,
## F2 pegarle arriba y el ascensor; R la vuelve a poner.

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

## El camino: qué brazos lleva.
var arms := Mech.Arms.POSE


func _init(arms_kind := Mech.Arms.POSE) -> void:
	arms = arms_kind
	display_name = Mech.NAMES[arms]


func max_footprint() -> Vector2:
	return Vector2(FOOTPRINT, FOOTPRINT)


func describe(_seed_value: int) -> PackedStringArray:
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
	var standing := MechSettings.current.hover_height + Mech.SIZE * 0.5
	# Nace donde va parada, mirando hacia donde uno llega (−X); la de práctica, adelante, mirándola.
	var mech := Mech.new()
	mech.arms_kind = arms
	mech.transform = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.0, standing, 0.0))
	root.add_child(mech)
	var target := Mech.new()
	target.arms_kind = Mech.Arms.NONE
	target.transform = Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-SPARRING, standing, 0.0))
	root.add_child(target)
	return root


func parcel_options() -> Array[Dictionary]:
	var options := TestBall.parcel_options(self)
	options.append({"key": KEY_U, "label": "subirse a la meca (al piso del medio)",
		"apply": func(parcel: SandboxParcel) -> void:
			for mech: Mech in parcel.find_children("*", "Mech", true, false):
				if mech.arms_kind != Mech.Arms.NONE:
					mech.cabin.board()})
	return options


func ball_shots() -> Array[Dictionary]:
	return [
		TestBall.shot("lenta, no la voltea", TestBall.push_for(Mech.MASS, SMALL, SLOW), SLOW),
		TestBall.shot("lenta, la voltea", TestBall.push_for(Mech.MASS, BIG, SLOW), SLOW),
		TestBall.shot("rápida, no la voltea", TestBall.push_for(Mech.MASS, SMALL, FAST), FAST),
		TestBall.shot("rápida, la voltea", TestBall.push_for(Mech.MASS, BIG, FAST), FAST),
	]
