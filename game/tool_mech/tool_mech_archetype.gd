class_name ToolMechArchetype
extends MechArchetype

## LA PARCELA DE LA MECA DE TRES (ToolMech), la segunda del sandbox, al lado de la del vórtice (el usuario, 15/11/2026:
## «una parcela nueva que esté al principio de todo, al lado de la de vórtice, así la iteramos rápido»): la meca, la de
## práctica adelante para pegarle, y una pila de cajas sueltas a un costado para tirarles. Lo demás, como la parcela de
## siempre (U subirse, la bola, pegarle, el ascensor).

## Las cajas para tirarles: cuántas, su lado (m) y lo que pesa cada una (kg).
const CRATES := 9
const CRATE := 2.0
const CRATE_MASS := 1500.0
## A cuánto va la de práctica (m, de centro a centro): más lejos que en la parcela de siempre, así la boca del cañón,
## con el brazo estirado, no queda adentro de su caja (desde adentro, un tiro no la toca).
const TARGET := 34.0


## LA DE CÁPSULAS (PodMech, ver PodCabin) en vez de la Meca de tres: la misma parcela, con su meca.
var pods := false


func _init(pod_mech := false) -> void:
	pods = pod_mech
	super(Mech.Arms.POSE, true, Mech.Cabin.PODS if pods else Mech.Cabin.SQUARE)
	display_name = "Meca de cápsulas" if pods else "Meca de tres"


func describe(_seed_value: int) -> PackedStringArray:
	if pods:
		return PackedStringArray([
			"la meca de cápsulas: torso macizo, una cápsula por puesto; cañón a la izquierda, puño a la derecha",
			"mirándola, O la posee (T cambia la vista) · F2 la forma: el torso, los radiales, brazos y piernas",
			"adelante, la de práctica; a la derecha, cajas para tirarles · U a la cápsula de arriba",
		])
	return PackedStringArray([
		"la meca de ejemplo: cañón de energía a la izquierda, taladro a la derecha, energía común, placas de blindaje",
		"mirándola, O la posee (T cambia la vista): sus controles, abajo a la derecha",
		"adelante, la de práctica; a la derecha, cajas para tirarles · U subirse",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = display_name
	parent.add_child(root)
	var mech: ToolMech = PodMech.new() if pods else ToolMech.new()
	mech.transform = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.0, Mech.standing_height(mech.cabin_shape), 0.0))
	root.add_child(mech)
	var target := Mech.new()
	target.arms_kind = Mech.Arms.NONE
	target.transform = Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-TARGET, Mech.standing_height(), 0.0))
	root.add_child(target)
	# Las cajas, en una pila de tres por tres, adelante a la derecha de la meca (que mira hacia −X).
	for i in CRATES:
		var crate := RigidBody3D.new()
		crate.mass = CRATE_MASS
		Clay.solid(crate, Vector3.ONE * CRATE, Vector3.ZERO, Clay.METAL.lerp(Color(0.7, 0.5, 0.3), 0.6))
		crate.position = Vector3(-30.0 + (i % 3) * (CRATE + 0.1), CRATE * 0.5 + (i / 3) * CRATE, -10.0)
		root.add_child(crate)
	return root
