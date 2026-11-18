class_name BaseWorld
extends Node3D

## LA BASE DEL JUEGO (ver docs/technical/flujo-de-partida.md): la escena a la que llevan «crear partida» y «unirse».
## Es un REFLEJO del sandbox, no una copia: la arma con lo mismo que la parcela Base (BaseLayout, con las medidas
## guardadas de BaseSettings), así lo que se mueve en el F1 cambia el juego.
##   · Un mundo de la red (grupo `net_world`, ver CharacterSpawner): los personajes NACEN EN LA ESCLUSA (`start_point`).
##   · La sucursal en red (BaseSync): el estado del host y la compuerta del techo, para todos.
##   · La meca jaula en el elevador, CONGELADA (el usuario, 18/11/2026: «está bien si queda la meca sin interacción…
##     como algo estático»): se deja asentar y después se apaga entera (sin física propia ni scripts; choca como algo
##     fijo), hasta que la meca vaya por la red.

const GROUP := "net_world"
## Lo que se la deja asentarse antes de congelarla (s).
const SETTLE := 1.5

var _spawner: CharacterSpawner


func _ready() -> void:
	add_to_group(GROUP)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.05, 0.05, 0.06)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.82, 0.84, 0.87)
	world.environment.ambient_light_energy = 0.45
	add_child(world)
	var base := Node3D.new()
	base.name = "Base"
	add_child(base)
	BaseLayout.build_into(base)
	BaseArchetype.place_mech(base)
	_freeze_mech.call_deferred(base)
	var characters := Node3D.new()
	characters.name = "Personajes"
	add_child(characters)
	add_child(BaseSync.new())
	_spawner = CharacterSpawner.new()
	_spawner.name = "CharacterSpawner"
	_spawner.characters_root = characters
	add_child(_spawner)


## DÓNDE APARECE UN PERSONAJE (lo pide CharacterSpawner): en la esclusa, cerca del medio, un poco al azar para que
## dos no nazcan uno encima del otro.
func start_point() -> Vector3:
	var side := BaseLayout.strip
	var middle := BaseLayout.at(BaseLayout.LENGTH + side * 0.5, BaseLayout.NAVE + side * 0.5, 1.0)
	return middle + Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))


func _freeze_mech(base: Node3D) -> void:
	await get_tree().create_timer(SETTLE).timeout
	for mech: Node in base.get_children():
		if mech is Mech:
			(mech as Mech).disable_mode = CollisionObject3D.DISABLE_MODE_MAKE_STATIC
			(mech as Mech).process_mode = Node.PROCESS_MODE_DISABLED
