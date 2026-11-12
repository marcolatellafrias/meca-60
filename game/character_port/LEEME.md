# Lo traído de character-parametric

El 11/11/2026 se trajeron de `D:\Godot\character-parametric` (su árbol de trabajo; último commit allá: `50a538ef`) el
personaje, agarrar, sentarse y la red, **pieza por pieza** (lo eligió el usuario: no la copia del proyecto entero).
Se fue siguiendo qué usa a qué desde el jugador, la silla, lo que se agarra y la red, y se cortó en la ciudad, el
tránsito, la nave y sus paneles.

## Copias tal cual (no se editan acá; si cambian allá, se vuelven a copiar)

- `game/character/` entera, `assets/models/character/`, `assets/audio/`, `assets/shaders/outline*.gdshader`.
- `game/interactables/`: la base (`Interactable`, `InteractionController`, `InteractionDetector`), lo que se agarra
  (`GrabbableInteractable`, `CharacterGrabbable`), lo que se sostiene (`HeldInteractable`), la silla
  (`SeatInteractable`, `ActivatableInteractable`, `ProceduralSeat` y su escena), los controles (`ControllableInteractable`,
  `RotatingComponent`, `TwoAxisComponent`, `GearShiftComponent`, `BellowsSleeve`).
- `game/net/` (sin el tránsito): `SessionManager`, `NetSpawner`, `CharacterSpawner`, `CharacterNetSync`, `NetBody`,
  `ExclusiveClaim`, `NameTag`, `SessionPlayer`. Y `addons/godotsteam` (sin los temporales de Windows) y
  `steam_appid.txt`.
- `game/objects/` (los paquetes y su daño), `game/particles/`, `game/sounds/`, `game/main/` (`WorldSettings`,
  `WorldSeeds`), `game/ship/working_seat.tscn` (la silla de las consolas), `game/city/props/unit_mesh.gd`.
- `game/common/`: `debug_util`, `mesh_kit`, `model_box`, `motion_frame` (el marco: lo que se mueve y lleva cosas),
  `physics_layers`.
- `game/debug/`: la depuración del personaje (`DebugPanel`, `ImpactDebugHUD`, `TunerPanel`, `PropertyTuner`…). *Las
  herramientas de esculpir el cuerpo (el inspector, la vista Blender, el alambre de quads, el esqueleto dibujado, la
  cámara orbital, el F3) se borraron el 13/11/2026.*
- `game/ui/`: `UIState`, `DevConsole`, `Crosshair`, el HUD del jugador, **la pausa** (la de allá: no frena el mundo, como
  en cooperativo) y `main_menu.tscn`.
- De `project.godot`: las acciones de teclado (`move_*`, `jump`, `sprint`, `interact`…), los nombres de las capas, la
  física a 240 pasos por segundo, `[steam]` y los autoloads de la red (`WorldSettings`, `SessionManager`, `UIState`,
  `DevConsole`, `NetSpawner`).

## Adaptadas (son de la meca, a partir de las de allá)

- `game/ui/main_menu.gd`: el menú de allá; la partida es el sandbox de la meca.
- `game/sandbox/sandbox_session.gd` y `multiplayer_archetype.gd`: la sesión del sandbox y la fila Multijugador, sin la
  nave compartida ni el tablero.
- `game/sandbox/design_sandbox.gd`: crea al jugador como allá (ente, y cuerpo con la B) y tiene la sesión.
- `game/common/motion_frame.gd`: **un arreglo**, también para llevar allá: `_carry_jump` convertía a `RigidBody3D` un
  cuerpo ya borrado antes de preguntar si existía (error «Trying to cast a freed object» al borrarse el ente al abrir
  la sesión). Ahora lo borra de los miembros, como ya hacía `_carry`.

## Esta carpeta: la frontera

Lo que lo traído usa y es de la ciudad, el tránsito, la nave o su depuración: acá cada uno con su nombre de allá y
sólo lo que se le pide, sin hacer nada (`City`, `CarBody`, `AreaInstantiator`, `TrafficDebugDrawer`, `CityDebugView`,
`CityMap`, `CityMapOverlay`, `WeatherTuner`, `PerformanceToggles`, `Inspector`, `DebugRam`, `ShipStyle` —con la altura
de ojos sentado de allá—, `NetworkParts`). Si un día se trae una de esas cosas de verdad, su pieza de acá se borra.

Las opciones (`GameOptions`, `OptionsMenu`) son las de la meca (de allá por el taxi, sin la voz): lo traído las usa
igual.
