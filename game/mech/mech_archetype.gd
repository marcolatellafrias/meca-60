class_name MechArchetype
extends SeededArchetype

## LAS REGLAS DE TODA PARCELA CON LA MECA PROPIA: sus teclas (la bola, U subirse, N/M pegarle), los tiros de la bola y
## su medida. La arma la de la meca jaula (CageMechArchetype, que la hereda); el Mapa de pelea y la Base las toman de
## acá para sus mecas.
## *Hasta el 17/11/2026 era también la parcela de las dos filas de la meca grande (la discreta y la física, con la
## cinemática y la de cápsulas por encima); se borraron con ella (están en el commit 0bcaeaf).*

## Grande: corre y salta.
const FOOTPRINT := 120.0
## LOS CUATRO TIROS (el usuario: «lento que no voltee, lento que voltee, rápido que no voltee y rápido que voltee»): la
## bola va lenta o rápida (m/s) y el golpe es chico o grande (m/s que le cambiaría la velocidad a la caja suelta).
const SLOW := 30.0
const FAST := 100.0
const SMALL := 5.0
const BIG := 14.0


func max_footprint() -> Vector2:
	return Vector2(FOOTPRINT, FOOTPRINT)


## LO QUE LLEVA SU MECA SIN NADA GUARDADO (ver Mech.default_loadout): lo que muestra el panel de equipamiento al volver
## a lo del código.
func default_loadout() -> Array[ArmLoadout]:
	return Mech.fists()


## La bola, subirse, y pegarle arriba suave o fuerte (eran el panel F2, MechKnockPanel: acciones de prueba, van en el
## panel chico; el usuario, 13/11/2026: «empuje liviano, empuje fuerte… deberían ir en panel chico»).
func keys() -> Array[SandboxKey]:
	var out := TestBall.keys(self)
	out.append(SandboxKey.action(KEY_U, SandboxKey.Weight.MAIN, "subirse a la meca (adentro)",
		func(parcel: SandboxParcel) -> void:
			for mech: Mech in parcel.find_children("*", "Mech", true, false):
				if mech.arms_kind != Mech.Arms.NONE and mech.cabin != null:
					mech.cabin.board()))
	out.append_array(MechArchetype.knock_keys())
	return out


## PEGARLE, para toda parcela con mecas. *Hasta el 17/11/2026 también subían y bajaban el ascensor de la meca grande.*
static func knock_keys() -> Array[SandboxKey]:
	return [
		SandboxKey.action(KEY_N, SandboxKey.Weight.NORMAL, "pegarle suave",
			func(parcel: SandboxParcel) -> void: _each(parcel, func(mech: Mech) -> void: mech.knock(false))),
		SandboxKey.action(KEY_M, SandboxKey.Weight.NORMAL, "pegarle fuerte",
			func(parcel: SandboxParcel) -> void: _each(parcel, func(mech: Mech) -> void: mech.knock(true))),
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
