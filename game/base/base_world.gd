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
##   · LA ARENA, ARRIBA (el paso 7): al arrancar el ascensor (BaseElevator.launching) se arma el mapa de pelea sobre el
##     pozo, con el hueco del ascensor en el medio, y se prende el sol. Las compuertas ocultan que recién se arma.
##   · EL JEFE DEL CONTRATO (el paso 8 es de Jefes: BossNet), en la arena, armado igual y con el mismo camino en todas las
##     máquinas (Arena/Jefe/Luchador). Duerme hasta que el ascensor llega arriba. Su blanco es la meca, que recibe vida.

const GROUP := "net_world"
## EL JEFE EN LA ARENA: dónde nace (enfrente de la boca del ascensor, mirándola), el círculo del que no sale (lo libre del
## medio del mapa: más allá están los barrios) y las vidas.
const BOSS_AT := Vector3(0.0, 0.0, 13.0)
const BOSS_RING := 62.0
const BOSS_HEALTH := 400.0
const MECH_HEALTH := 100.0
var _spawner: CharacterSpawner
var _environment: Environment
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
	_environment = world.environment
	add_child(world)
	var base := Node3D.new()
	base.name = "Base"
	add_child(base)
	BaseLayout.build_into(base)
	BaseArchetype.place_mech(base)
	var airlock := base.find_child("Esclusa", true, false) as BaseAirlock
	airlock.opened.connect(_crew_aboard.bind(base))
	var elevator := base.find_child("Ascensor", true, false) as BaseElevator
	elevator.launching.connect(_build_arena.bind(base))
	elevator.arrived.connect(_wake_boss)
	var characters := Node3D.new()
	characters.name = "Personajes"
	add_child(characters)
	add_child(BaseSync.new())
	add_child(BaseSupplies.new())
	add_child(BaseRoomCode.new())
	add_child(BasePanels.new())
	_spawner = CharacterSpawner.new()
	_spawner.name = "CharacterSpawner"
	_spawner.characters_root = characters
	add_child(_spawner)
	# LA PARTIDA SE VE EN ISOMÉTRICA (ver IsoView).
	add_child(IsoView.new())


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


## LA ARENA SOBRE EL POZO: el mapa de pelea con el hueco del ascensor justo arriba de la plataforma, el piso a ras de la
## compuerta de arriba. Sin recursos por ahora (todavía no van por la red). Y la luz de afuera: el sol y el cielo.
func _build_arena(base: Node3D) -> void:
	if get_node_or_null("Arena") != null:
		return
	var holder := base.get_node("Plano") as Node3D
	var arena := Node3D.new()
	arena.name = "Arena"
	add_child(arena)
	arena.global_position = holder.to_global(BaseLayout.at(BaseLayout.ELEVATOR * 0.5, BaseLayout.NAVE * 0.5,
		BaseLayout.shaft_top()))
	Battlefield.build(arena, BaseLayout.span(), false)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 300.0
	arena.add_child(sun)
	# SIN VERSE HASTA LLEGAR: su piso queda entre la cámara y la base, y ya nada lo oculta solo.
	arena.visible = false
	_spawn_boss(arena, base)


## EL JEFE DEL CONTRATO. Por ahora hay uno solo hecho, el Luchador (Brawler), y hace de todos los contratos; el
## nombre de su barra es el del contrato. Armado como su parcela (BrawlerArchetype), pero en la arena y dormido.
func _spawn_boss(arena: Node3D, base: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "Jefe"
	arena.add_child(holder)
	var boss := Brawler.new()
	boss.name = "Luchador"
	boss.position = BOSS_AT
	boss.rotation.y = PI
	holder.add_child(boss)
	Health.attach(boss, BOSS_HEALTH)
	boss.arena = BossArena.new(holder, BOSS_RING)
	var brain := BrawlerBrain.new()
	brain.name = "Cabeza"
	brain.awake = false
	boss.add_child(brain)
	# su letrero de lo que hace es del sandbox (para probar los poderes): en la partida, no
	for sign: Node in boss.find_children("*", "Label3D", false, false):
		(sign as Label3D).visible = false
	var mech := base.get_node_or_null("Meca jaula") as Mech
	if mech != null:
		if mech.get_node_or_null(Health.NODE_NAME) == null:
			Health.attach(mech, MECH_HEALTH)
		brain.target = mech
	var bars := FightBars.new()
	bars.name = "Barras"
	bars.boss = boss
	bars.mech = mech
	var contract := BaseState.current.contract
	bars.boss_name = str(ContractsCatalog.CONTRACTS[contract].boss).to_upper() if contract >= 0 else "EL JEFE"
	holder.add_child(bars)
	if mech != null:
		MatchEnd.watch(holder, mech, boss)


## Al llegar arriba, el jefe se despierta.
func _wake_boss() -> void:
	var arena := get_node_or_null("Arena") as Node3D
	if arena != null:
		arena.visible = true
		_environment.background_color = Color(0.75, 0.82, 0.9)
	var brain := get_node_or_null("Arena/Jefe/Luchador/Cabeza") as BrawlerBrain
	if brain != null:
		brain.awake = true
