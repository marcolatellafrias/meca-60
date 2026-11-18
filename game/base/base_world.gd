class_name BaseWorld
extends Node3D

## LA BASE DEL JUEGO (ver docs/technical/flujo-de-partida.md): la escena a la que llevan «crear partida» y «unirse».
## Es un REFLEJO del sandbox, no una copia: la arma con lo mismo que la parcela Base (BaseLayout, con las medidas
## guardadas de BaseSettings), así lo que se mueve en el F1 cambia el juego.
##   · Un mundo de la red (grupo `net_world`, ver CharacterSpawner): los personajes NACEN EN LA ESCLUSA (`start_point`).
##   · La sucursal en red (BaseSync): el estado del host y la compuerta del techo, para todos.
##   · La meca jaula en el elevador, por la red (BodyNet: la simula su dueño, el host o el que la maneja). AL ABRIR LA
##     ESCLUSA SE ARMA PARA LOS QUE SON (CageShape.crew: de 1, 2 o 3 puestos), con la cuenta del host, igual en todas
##     las máquinas. *Hasta el 19/11/2026 estuvo congelada, como decorado, mientras la meca no iba por la red.*

const GROUP := "net_world"
var _spawner: CharacterSpawner
## El jugador local al que ya se le dio vuelta hacia la compuerta (se vuelve a hacer si nace de nuevo).
var _faced: Node


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
	var airlock := base.find_child("Esclusa", true, false) as BaseAirlock
	airlock.opened.connect(_crew_aboard.bind(base))
	var characters := Node3D.new()
	characters.name = "Personajes"
	add_child(characters)
	add_child(BaseSync.new())
	_spawner = CharacterSpawner.new()
	_spawner.name = "CharacterSpawner"
	_spawner.characters_root = characters
	add_child(_spawner)


## NACER MIRANDO A LA COMPUERTA DE ADELANTE (la que da a la franja, hacia −X): apenas el jugador local tiene su
## control, se le da vuelta la mirada.
func _process(_delta: float) -> void:
	var player := _spawner.local_player if is_instance_valid(_spawner) else null
	if not is_instance_valid(player) or player == _faced or not is_instance_valid(player.player_controller):
		return
	player.player_controller.camera_yaw = PI * 0.5
	_faced = player


## DÓNDE APARECE UN PERSONAJE (lo pide CharacterSpawner): en la esclusa, cerca del medio, un poco al azar para que
## dos no nazcan uno encima del otro.
func start_point() -> Vector3:
	var side := BaseLayout.strip
	var middle := BaseLayout.at(BaseLayout.LENGTH + side * 0.5, BaseLayout.NAVE + side * 0.5, 1.0)
	return middle + Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))


## LA MECA PARA LOS QUE SON (el paso 6 de flujo-de-partida): de 1, 2 o 3 puestos (más de 3 jugadores, la de 3).
func _crew_aboard(players: int, base: Node3D) -> void:
	CageShape.crew = clampi(players, 1, 3) - 1
	BaseArchetype.place_mech(base)
