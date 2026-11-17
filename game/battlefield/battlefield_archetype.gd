class_name BattlefieldArchetype
extends SeededArchetype

## LA PARCELA DEL MAPA DE PELEA (ver Battlefield y docs/technical/mapa.md): el mapa entero, una meca para manejar (la jaula,
## CageMech, con el equipo de su fila) donde nace, mirando al centro, y una meca de práctica sin brazos más allá del
## medio, de jefe quieto. Sus teclas son las de la meca (U subirse, J/K la bola: ver MechArchetype). R lo vuelve a armar
## (los recursos vuelven a su lugar). *Hasta el 17/11/2026 la meca era la discreta de la meca grande, borrada ese día.*

const FOOTPRINT := (Battlefield.RADIUS + Battlefield.WALL_THICK + 6.0) * 2.0
## Dónde queda la de práctica.
const SPARRING := Vector2(0.0, -20.0)

## Las reglas de la meca (sus teclas y los tiros de la bola), de su propia parcela.
var _mech_rules := MechArchetype.new()


func _init() -> void:
	display_name = "Mapa de pelea"


func max_footprint() -> Vector2:
	return Vector2(FOOTPRINT, FOOTPRINT)


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"arena de Ø 260 m, casi toda libre para las mecas; en el borde, cuatro barrios con escaleras para subir a los techos",
		"recursos frente a cada barrio (bandera amarilla) y arriba de algún edificio alto",
		"al medio, tres ruinas para cubrirse · la meca de práctica hace de jefe quieto",
		"mirando la meca, O la posee · U subirse · Shift con una dirección, dash · espacio salta",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "MapaDePelea"
	parent.add_child(root)
	Battlefield.build(root)
	var standing := Mech.standing_height()
	var mech := CageMech.new()
	mech.equipment = CageMechArchetype.ROW
	mech.position = Vector3(Battlefield.SPAWN.x, standing, Battlefield.SPAWN.y)
	root.add_child(mech)
	var target := Mech.new()
	target.arms_kind = Mech.Arms.NONE
	target.transform = Transform3D(Basis(Vector3.UP, PI), Vector3(SPARRING.x, standing, SPARRING.y))
	root.add_child(target)
	return root


func keys() -> Array[SandboxKey]:
	return _mech_rules.keys()


func ball_shots() -> Array[Dictionary]:
	return _mech_rules.ball_shots()
