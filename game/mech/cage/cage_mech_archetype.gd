class_name CageMechArchetype
extends ToolMechArchetype

## LA PARCELA DE LA MECA JAULA (CageMech), la primera del sandbox (16/11/2026): la meca, la de práctica adelante para
## pegarle y una pila de cajas chicas a un costado, a su medida.

const CAGE_TARGET := 18.0
const SMALL_CRATE := 0.63
const SMALL_CRATE_MASS := 300.0


func _init() -> void:
	super()
	cabin_shape = Mech.Cabin.CAGE
	display_name = "Meca jaula"


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"la meca jaula: abajo el que maneja, arriba el de los brazos, atrás el artillero; cañón a la izquierda, palo a la derecha",
		"mirándola, O la posee (T cambia la vista): sus controles, abajo a la derecha · F1 su forma de moverse",
		"adelante, la de práctica; a la derecha, cajas para tirarles · U a la cubierta",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = display_name
	parent.add_child(root)
	var mech := CageMech.new()
	mech.transform = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.0, Mech.standing_height(mech.cabin_shape), 0.0))
	root.add_child(mech)
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
