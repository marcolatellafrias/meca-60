class_name GunnerFx
extends RefCounted

## LO QUE SE VE AL DISPARAR Y AL PEGAR, para las armas del artillero (ver GunnerWeapons): las partículas de la fila
## Partículas (ParticleSystems), de ráfaga, que se borran solas.


## CHISPAS donde pega una bala, de `size`.
static func sparks(at: Vector3, size: float) -> void:
	_burst(ParticleSystems.explosion_sparks(ParticleMeshes.Kind.LINE, size), at, 1.2)


## UNA EXPLOSIÓN en `at`, de `size`: el destello, las chispas y el polvo.
static func blast(at: Vector3, size: float) -> void:
	_burst(ParticleSystems.explosion_flash(ParticleMeshes.Kind.SPHERE, size), at, 1.0)
	_burst(ParticleSystems.explosion_sparks(ParticleMeshes.Kind.LINE, size), at, 1.2)
	_burst(ParticleSystems.impact_dust(ParticleMeshes.Kind.SPHERE, size), at, 2.5)


## EL FOGONAZO en la boca de un arma: un destello chico.
static func muzzle(at: Vector3, size: float) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.current_scene != null:
		EnergyBolt.flash(tree.current_scene, at, size, Color(1.0, 0.85, 0.45))


static func _burst(emitter: GPUParticles3D, at: Vector3, lifetime: float) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		emitter.free()
		return
	tree.current_scene.add_child(emitter)
	emitter.global_position = at
	emitter.restart()
	tree.create_timer(lifetime).timeout.connect(emitter.queue_free)
