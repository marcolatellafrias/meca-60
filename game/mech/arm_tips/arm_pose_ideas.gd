class_name ArmPoseIdeas
extends RefCounted

## LAS IDEAS DE POSES DE LOS BRAZOS, PARA PROBARLAS JUGANDO (16/11/2026, el usuario: «¿podrías poner todas las poses
## para probar, en un panel F temporal, así veo?»): dónde descansa el brazo de piñas, dónde descansa el cañón (estirado o
## en L) y el golpe del palo. Las mismas de las hojas (tests/arm_rest_look, tests/arm_attack_look); las elige el panel
## de poses (ArmPosesPanel, ArmPoseTrial) y las pone `apply` en las mecas con brazos de herramientas (ToolMech). La 1 de
## cada lista es como estaba: sin tocar el panel, nada cambia. *Temporal: cuando el usuario elija, lo elegido pasa a ser
## lo de cada punta y esto se borra.*

## EL BRAZO DE PIÑAS: dónde se pide el puño, desde el hombro, en el largo de los brazos (como MechArm.STANCES: x hacia
## afuera de su lado, −z adelante).
const FISTS := [
	["hoy: al costado, abajo", Vector3(0.4, -6.2, -4.4)],
	["guardia de boxeo: adelante, a la altura de los ojos", Vector3(-1.6, -1.5, -6.6)],
	["guardia baja: adelante, a la altura del pecho", Vector3(-1.0, -3.5, -7.0)],
	["adelante y afuera, listo para pegar", Vector3(1.2, -3.0, -7.5)],
	["abajo y adelante: en el borde de la vista", Vector3(0.2, -4.8, -6.8)],
	["alto y afuera", Vector3(1.5, -0.5, -5.5)],
	["cruzado adelante del vidrio", Vector3(-2.5, -3.0, -6.5)],
	["estirado al frente", Vector3(0.0, -2.0, -9.5)],
]
## EL CAÑÓN ESTIRADO: la palanca (grados en el espacio del torso: x a la derecha —para el izquierdo, adentro—, y arriba)
## y cuánto se estira (partes de lo que mide estirado).
const CANNONS := [
	["hoy: al frente, estirado", Vector2(0.0, -5.0), 0.995],
	["estirado, apuntando abajo", Vector2(0.0, -30.0), 0.995],
	["estirado, abajo y adentro", Vector2(18.0, -30.0), 0.995],
	["doblado, a la cadera", Vector2(5.0, -35.0), 0.6],
	["doblado al frente, a la altura del pecho", Vector2(0.0, -10.0), 0.7],
	["estirado, hacia afuera", Vector2(-15.0, -12.0), 0.995],
	["doblado, al hombro, apuntando arriba", Vector2(5.0, 25.0), 0.8],
	["medio doblado, afuera y abajo", Vector2(-10.0, -25.0), 0.85],
]
## EL CAÑÓN EN L: la punta del brazo (partes del brazo entero, desde el hombro: x afuera, y arriba, −z adelante) y hacia
## dónde dobla el codo (MechArm.elbow_hint: x afuera, y arriba, z atrás; cero, el de siempre).
const CANNON_L := [
	["L: codo pegado abajo, cañón al frente", Vector3(0.0, -0.5, -0.5), Vector3(0.0, -1.0, 0.2)],
	["la misma L con el codo de siempre (afuera)", Vector3(0.0, -0.5, -0.5), Vector3.ZERO],
	["L, el cañón cruzando hacia adentro", Vector3(-0.22, -0.48, -0.45), Vector3(0.0, -1.0, 0.2)],
	["L alta: el cañón a la altura del pecho", Vector3(-0.08, -0.32, -0.6), Vector3(0.0, -1.0, 0.0)],
	["L baja: el cañón inclinado abajo", Vector3(0.0, -0.62, -0.38), Vector3(0.0, -1.0, 0.3)],
	["codo atrás: el cañón pegado a la panza", Vector3(-0.1, -0.42, -0.28), Vector3(0.0, -0.6, 1.0)],
	["L adentro y alta: bien en la vista", Vector3(-0.32, -0.3, -0.52), Vector3(0.3, -1.0, 0.2)],
	["L con el codo pegado y el cañón un poco afuera", Vector3(0.18, -0.5, -0.45), Vector3(-0.2, -1.0, 0.2)],
]
## EL GOLPE DEL PALO (el clic izquierdo): la piña de MechArm y, si va por otro camino, sus puntos (como MechArm.PUNCHES).
const STRIKES := [
	["hoy: el directo", MechArm.Punch.STRAIGHT, []],
	["mazazo de arriba", MechArm.Punch.HAMMER, []],
	["barrido de costado, abierto y bajo", MechArm.Punch.HOOK,
		[[0.5, Vector3(5.0, -2.0, -1.5)], [0.3, Vector3(-6.0, -2.5, -6.5)], [0.2, Vector3(-6.0, -2.5, -6.5)]]],
]


## PONE LO ELEGIDO (ArmPoseTrial.current) en `mech`: el reposo y el golpe de su brazo de piñas, el reposo del cañón.
static func apply(mech: ToolMech) -> void:
	var trial := ArmPoseTrial.current
	if mech.melee != null:
		mech.melee.rest_point = FISTS[trial.fist_rest][1]
		mech.melee.main_punch = STRIKES[trial.strike][1]
		mech.melee.main_path = STRIKES[trial.strike][2]
	if mech.cannon != null:
		cannon_rest(mech.cannon, trial.cannon_rest)


## EL REPOSO DEL CAÑÓN `index`: las estiradas (CANNONS) y, después, las en L (CANNON_L).
static func cannon_rest(cannon: CannonTip, index: int) -> void:
	if index < CANNONS.size():
		cannon.lever = CANNONS[index][1]
		cannon.stretch = CANNONS[index][2]
		cannon.arm.elbow_hint = Vector3.ZERO
		return
	var idea: Array = CANNON_L[index - CANNONS.size()]
	# La palanca va en el espacio del torso (x a la derecha): del lado izquierdo, afuera es −x.
	var point: Vector3 = idea[1]
	var across := cannon.arm.side * point.x
	cannon.lever = Vector2(rad_to_deg(atan2(across, -point.z)), rad_to_deg(atan2(point.y, Vector2(across, point.z).length())))
	cannon.stretch = point.length()
	cannon.arm.elbow_hint = idea[2]


## En todas las mecas con brazos de herramientas del árbol.
static func apply_all(tree: SceneTree) -> void:
	for found in tree.root.find_children("*", "ToolMech", true, false):
		if not found.is_queued_for_deletion() and not (found as ToolMech).arms.is_empty():
			apply(found)
