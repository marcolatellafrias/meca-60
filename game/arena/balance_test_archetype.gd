class_name BalanceTestArchetype
extends SeededArchetype

## LA PARCELA DEL EQUILIBRIO: la meca de equilibrio (MechDummy, el sistema de los personajes de character-parametric)
## sola en un piso, con una persona al lado para la escala. J le tira una bola desde la cámara, con la fuerza que se
## elige con K y L, para ver cómo reacciona a distintos empujones (lo pidió el usuario el 11/11/2026).

const FOOTPRINT := 70.0

var level := 2


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
	# Una persona, para la escala.
	Clay.box(root, Vector3(0.5, 1.8, 0.3), Vector3(-14.0, 0.9, 8.0), Clay.DARK)
	return root


func parcel_options() -> Array[Dictionary]:
	return [
		{"key": KEY_J, "label": func() -> String: return "tirar una bola (fuerza %d de %d: %d m/s)" % [level + 1,
				TestBall.SPEEDS.size(), roundi(float(TestBall.SPEEDS[level]))],
			"apply": func(parcel: SandboxParcel) -> void: TestBall.throw_from_camera(parcel, level)},
		{"key": KEY_K, "label": "menos fuerza",
			"apply": func(_parcel: SandboxParcel) -> void: level = maxi(level - 1, 0)},
		{"key": KEY_L, "label": "más fuerza",
			"apply": func(_parcel: SandboxParcel) -> void: level = mini(level + 1, TestBall.SPEEDS.size() - 1)},
	]
