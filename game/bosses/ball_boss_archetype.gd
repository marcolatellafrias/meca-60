class_name BallBossArchetype
extends SeededArchetype

## LA PARCELA DEL JEFE BOLA (BallBoss): la bola sola, con un edificio y una pared larga para ver cómo choca y cómo pisan
## los tentáculos lo que no es piso parejo. Mirándola, la O la posee.

const FOOTPRINT := 180.0
const START := Vector3(0.0, 0.0, 30.0)
## Las cajas para pegarles: cuántas, su lado (m) y lo que pesan (kg).
const CRATES := 8
const CRATE := 3.0
const CRATE_MASS := 400.0


func _init() -> void:
	display_name = "Jefe bola"


func max_footprint() -> Vector2:
	return Vector2(FOOTPRINT, FOOTPRINT)


func far_height() -> float:
	return 35.0


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"la bola con su rendija, el cañón que corre por ella y cuatro tentáculos",
		"más del doble de la meca; contra lo fijo es un cilindro, como el cubo cinemático",
		"Shift hecha bola: rueda, dobla y pega a lo que toca (las cajas) · O poseerla · F1 las perillas · R las cajas de nuevo",
		"poseída: WASD, el mouse gira y sube o baja el cañón, Ctrl se agacha, espacio salta (sólo para arriba)",
		"clic izquierdo el tiro simple, clic derecho misiles del cielo uno tras otro",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Jefe bola"
	parent.add_child(root)
	var boss := BallBoss.new()
	boss.name = "Bola"
	boss.position = START
	# Por donde salen sus tiros: un hijo fijo de la parcela, igual en todas las máquinas (ver ProjectileField).
	var field := ProjectileField.new()
	field.name = "Proyectiles"
	root.add_child(field)
	root.add_child(boss)
	boss.cannon.field = field
	# LO FIJO: un edificio a la izquierda (se puede pisar el techo) y una pared larga a la derecha.
	var fixed := StaticBody3D.new()
	fixed.name = "Fijo"
	PhysicsLayers.mark_fixed(fixed)
	root.add_child(fixed)
	Clay.solid(fixed, Vector3(20.0, 12.0, 40.0), Vector3(-45.0, 6.0, -10.0), Clay.METAL.lightened(0.2))
	Clay.solid(fixed, Vector3(2.0, 16.0, 70.0), Vector3(50.0, 8.0, 0.0), Clay.METAL.lightened(0.1))
	# LO SUELTO: una fila de cajas adelante, para pegarles rodando (la R las vuelve a poner).
	var crates := Node3D.new()
	crates.name = "Cajas"
	root.add_child(crates)
	for i in CRATES:
		var crate := RigidBody3D.new()
		crate.mass = CRATE_MASS
		crate.position = Vector3((i - (CRATES - 1) * 0.5) * (CRATE + 2.0), CRATE * 0.5, -15.0)
		crates.add_child(crate)
		Clay.solid(crate, Vector3.ONE * CRATE, Vector3.ZERO, Clay.YELLOW.darkened(0.2 if i % 2 == 0 else 0.35))
	return root
