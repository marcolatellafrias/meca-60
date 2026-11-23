class_name MechSmoke
extends Node3D

## EL HUMO DE LA MECA LASTIMADA (22/11/2026): se ve de lejos que le hace falta un kit de reparación. Sale de arriba mientras su
## vida esté por debajo de `BELOW`.

const BELOW := 0.75
const SIZE := 1.6

var mech: Mech = null
var _smoke: GPUParticles3D = null


func _ready() -> void:
	name = "Humo"
	_smoke = ParticleSystems.thruster_smoke(ParticleMeshes.Kind.SPHERE, SIZE)
	_smoke.rotation_degrees = Vector3(180.0, 0.0, 0.0)
	add_child(_smoke)
	_smoke.emitting = false
	position = Vector3.UP * (CageCabin.shape().height() * 0.5 + 0.6)


func _process(_delta: float) -> void:
	var life := Health.of(mech)
	_smoke.emitting = life != null and not life.dead() and life.share() < BELOW
