class_name BalanceTestArchetype
extends SeededArchetype

## LA PARCELA DEL EQUILIBRIO: la meca de equilibrio (MechDummy, el sistema de los personajes de character-parametric)
## en un piso, con dos personas de character-parametric al lado (el gordo y el chico; ver PeopleArchetype) para la
## escala y para ver que reaccionan con el mismo sistema. J les tira una bola desde la cámara, K y L la fuerza y M la
## bola (grande para la meca, chica para las personas; ver TestBall). Lo pidió el usuario el 11/11/2026.

## Lo que ocupa la meca parada, con lugar para trastabillar (cayéndose sale de la parcela, y está bien: el piso sigue).
const FOOTPRINT := 30.0


func _init() -> void:
	display_name = "Meca de equilibrio"


func max_footprint() -> Vector2:
	return Vector2(FOOTPRINT, FOOTPRINT)


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"el equilibrio de los personajes de character-parametric",
		"se tambalea, se cae y se levanta; no camina ni pega",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Equilibrio"
	parent.add_child(root)
	var dummy := MechDummy.new()
	dummy.name = "Meca de equilibrio"
	# Mirando hacia donde uno llega (−X).
	dummy.rotation.y = PI * 0.5
	root.add_child(dummy)
	# Dos personas al costado, mirando hacia donde uno llega, como la meca.
	var side := root.global_position + Vector3(-9.0, 0.0, 8.0)
	PeopleArchetype.spawn(root, EntityArchetype.Archetype.fat_man, side, PI * 0.5)
	PeopleArchetype.spawn(root, EntityArchetype.Archetype.kid, side + Vector3(0.0, 0.0, 2.5), PI * 0.5)
	return root


func parcel_options() -> Array[Dictionary]:
	return TestBall.parcel_options(self)


func ball_pushes() -> Array[float]:
	return MechDummy.ball_pushes(TestBall.SPEED)
