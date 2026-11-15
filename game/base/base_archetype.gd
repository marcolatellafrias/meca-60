class_name BaseArchetype
extends SeededArchetype

## LA PARCELA DE LA BASE (ver BaseLayout y docs/technical/sucursal.md): la sucursal en arcilla, con la meca dormida en el
## elevador, mirando al gimnasio. Sus teclas son las de la meca (U subirse, J/K la bola: ver MechArchetype) y la G, que
## abre y cierra la compuerta del techo (lo que va a pasar al empezar una partida).

## Las reglas de la meca (sus teclas y los tiros de la bola), de su propia parcela.
var _mech_rules := MechArchetype.new(Mech.Arms.POSE)
## La compuerta de la base armada (se vuelve a buscar si se regeneró).
var _hatch: BaseHatch


func _init() -> void:
	display_name = "Base"


func max_footprint() -> Vector2:
	return BaseLayout.SIZE + Vector2(6.0, 6.0)


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"la sucursal, en arcilla: un solo piso, todo al mismo nivel (plano 6)",
		"el elevador, donde duerme la meca · el gimnasio con la bolsa",
		"la franja: contratos, armería, cosméticos y pintura, casilleros, el ascensor de personal",
		"mirando la meca, O la posee · U subirse · G abre la compuerta del techo",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Base"
	parent.add_child(root)
	BaseLayout.build(root)
	_hatch = root.get_node("Compuerta") as BaseHatch
	var mech := Mech.new()
	mech.arms_kind = Mech.Arms.POSE
	var spot := BaseLayout.at(BaseLayout.MECH_AT.x, BaseLayout.MECH_AT.y, Mech.standing_height())
	mech.transform = Transform3D(Basis(Vector3.UP, -PI * 0.5), spot)
	root.add_child(mech)
	return root


func keys() -> Array[SandboxKey]:
	var out := _mech_rules.keys()
	out.append(SandboxKey.toggle(KEY_G, SandboxKey.Weight.NORMAL, "compuerta del techo",
		func() -> bool: return is_instance_valid(_hatch) and _hatch.is_open,
		func(_parcel: SandboxParcel, on: bool) -> void:
			if is_instance_valid(_hatch):
				_hatch.set_open(on)))
	return out


func ball_shots() -> Array[Dictionary]:
	return _mech_rules.ball_shots()
