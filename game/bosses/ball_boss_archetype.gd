class_name BallBossArchetype
extends SeededArchetype

## LA PARCELA DEL JEFE BOLA (BallBoss): la bola sola, con un edificio y una pared larga para ver cómo choca y cómo pisan
## los tentáculos lo que no es piso parejo. Mirándola, la O la posee.

const FOOTPRINT := 180.0
const START := Vector3(0.0, 0.0, 30.0)


func _init() -> void:
	display_name = "Jefe bola"


func max_footprint() -> Vector2:
	return Vector2(FOOTPRINT, FOOTPRINT)


func far_height() -> float:
	return 37.0


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"PASO 1: la bola con su rendija y cuatro tentáculos (sin cañón todavía)",
		"más del doble de la meca; contra lo fijo es un cilindro, como el cubo cinemático",
		"O poseerla · F1 las perillas",
		"poseída: WASD, mouse gira, Ctrl se agacha (baja la bola), espacio salta (sólo para arriba)",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Jefe bola"
	parent.add_child(root)
	var boss := BallBoss.new()
	boss.name = "Bola"
	boss.position = START
	root.add_child(boss)
	# LO FIJO: un edificio a la izquierda (se puede pisar el techo) y una pared larga a la derecha.
	var fixed := StaticBody3D.new()
	fixed.name = "Fijo"
	PhysicsLayers.mark_fixed(fixed)
	root.add_child(fixed)
	Clay.solid(fixed, Vector3(20.0, 12.0, 40.0), Vector3(-45.0, 6.0, -10.0), Clay.METAL.lightened(0.2))
	Clay.solid(fixed, Vector3(2.0, 16.0, 70.0), Vector3(50.0, 8.0, 0.0), Clay.METAL.lightened(0.1))
	return root
