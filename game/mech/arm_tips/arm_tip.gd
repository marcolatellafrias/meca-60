class_name ArmTip
extends Node3D

## LO QUE VA EN LA PUNTA DE UN BRAZO DE LA MECA (16/11/2026, el usuario: «unificar el sistema de los brazos, ver qué
## cosas se equipan»): una pieza que se monta igual en un brazo discreto (PoseArm) o en uno con músculos (MuscleArm),
## que sólo dicen cómo se mueve el brazo. Ésta, la de siempre: EL PUÑO COMÚN (MechHand). Las otras la extienden:
##   · HeavyFistTip, el puño pesado; PoleTip, el puño pesado agarrando el palo eléctrico.
##   · DrillTip y SawTip (SpinTip): se cargan girando y se descargan con un directo.
##   · CannonTip: el cañón de energía en lugar del antebrazo, con su palanca y sus cuatro modos.
## Las monta el brazo (MechArm._mount_hand) en la punta del antebrazo, y las llama en cada paso. Qué lleva cada brazo de
## una meca, en ArmLoadout.

## El brazo que la lleva y la pieza de su antebrazo (el −Z de la pieza va hacia la mano; ver MechArm._along).
var arm: MechArm = null
var forearm: Node3D = null
## De dónde saca la energía (la de la meca; sin energía, lo que la gasta no anda).
var energy: MechEnergy = null


func _init() -> void:
	name = "Punta"
	# Lo que dibuja aparte (el rayo del cañón) se pone en el mundo.
	top_level = true


## La monta el brazo, con sus piezas ya armadas.
func mount(on: MechArm, piece: Node3D) -> void:
	arm = on
	forearm = piece
	_build()


## ── LO QUE CADA PUNTA CAMBIA ─────────────────────────────────────────────────────────────────────────────────────

## Arma lo suyo en la punta del antebrazo. El de siempre: la mano.
func _build() -> void:
	arm.mount_common_hand(forearm)


## Cada paso, antes de la pose (después de que el brazo avanza su piña y su postura).
func step(_delta: float) -> void:
	pass


## DÓNDE SE PIDE EL PUÑO: lo que piden las piñas y las posturas (`asked`, desde el hombro), o lo que diga la punta.
func wanted(asked: Vector3) -> Vector3:
	return asked


## LO QUE GOLPEA DE LA PUNTA (puntos en el mundo; ver MechArm._strike). La de siempre: el medio del puño, en la punta
## del antebrazo.
func strike_points() -> PackedVector3Array:
	var k := arm.measures.thick
	return PackedVector3Array([forearm.global_transform * Vector3(0, 0, -arm.forearm_length() * 0.5 - MechHand.length() * k * 0.5)])


## LO QUE CHOCA DE LA PUNTA, además del puño (ver StrikeSettings): [forma, dónde va en la pieza del antebrazo]. La de
## siempre, nada más.
func solid_shapes() -> Array:
	return []


## SI ES UN ARMA (el cañón): para StrikeSettings.weapon_collides.
func is_weapon() -> bool:
	return false


## EL GOLPE PRINCIPAL DE ESTA PUNTA, si no es una piña (puntos como MechArm.PUNCHES); vacío, la piña de siempre.
func strike_path() -> Array:
	return []


## AL CONECTAR un golpe: si la punta se encarga (y no el golpe de siempre).
## UNA PIÑA QUE MANDÓ EL DUEÑO por la red acaba de salir de este brazo (MechArmsNet): lo que la punta haga al tirarla.
func on_net_punch() -> void:
	pass


func hit(_body: RigidBody3D, _at: Vector3, _velocity: Vector3) -> bool:
	return false


## Si el antebrazo lleva placa (si la punta no lo reemplaza).
func plates_forearm() -> bool:
	return true


## Lo que muestra poseyéndola (vacío, nada).
func status() -> String:
	return ""


## La boca del antebrazo, por donde sale lo que no es el puño común (ver ArmoryParts.MOUTH), en la punta de la pieza.
func _mouth() -> void:
	var k := arm.measures.thick
	Clay.cylinder(forearm, ArmoryParts.MOUTH * k, 0.7 * k, Vector3(0, 0, -arm.forearm_length() * 0.5 + 0.05 * k),
		ArmoryParts.FOREARM_COLOR.darkened(0.15), Vector3(90, 0, 0))
