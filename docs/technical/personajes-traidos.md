# Lo traído de character-parametric

`game/character/`, `game/interactables/`, `game/supplies/` (los paquetes), `game/common/`… (ver abajo qué se trajo y dónde se cortó). **Ya es código de la meca**: se edita y se simplifica.

- **El jugador** es el personaje de allá: ente (sin cuerpo, **V** vuela) o cuerpo con **B** (el gordo atlético).
- Agarrar (clic izquierdo), sentarse (**E**), empujar (**R**).
- Fila **Personajes**: los seis arquetipos, que se caen y se levantan (`CharacterGetUp`). Fila **Objetos**: paquetes y
  una silla.

## El cuerpo (13/11/2026)
Seis arquetipos (gordo, musculoso, flaco alto, chico, viejo, gordo atlético), cada uno con sus proporciones y sus
números de juego (peso, fuerza, velocidad). **Nada más**: sin trajes, sombreros ni herramientas de esculpir.
- **La forma de bloques** (`BlockShape`: unos pocos metros por arquetipo, la de fábrica en `FACTORY` o la guardada en
  `block_shapes.tres`) es el cuerpo que se ve (`BlockBody`: cajas y cápsulas) y **de ella salen todas las medidas**
  (`SkeletonSizesUtil`): los huesos, la cadera, los hombros, el alto, la cápsula, la marcha. Encima, la postura y el
  andar del arquetipo (`EntityArchetype`, con lo guardado en `pose_shapes_low.tres`), y al final su tamaño
  (`body_scale`) y la lupa.
- **La cabeza** es una forma low poly (`HeadForm`: ocho lados, una arista por loop cut, sombreado suave) llevada al alto
  de la forma de bloques. El cuello nunca es más ancho que la cabeza donde entra (si no, asomaba como papada).
- **El reposo de cada hueso** (para dónde apunta) es una tabla, `CustomBonesUtil.REST`. *Antes se leía de un modelo de
  Blender, borrado.*
- *El 13/11/2026 cambiaron dos cosas al rehacer las medidas, a propósito: la postura de hombros es el ángulo que pide el
  arquetipo (la cuenta vieja lo multiplicaba por una escala, por error: de 7° a 5° en el gordo), y las cápsulas del
  ragdoll son del ancho de la caja o el miembro de cada hueso.*

## La fila Locomoción (13/11/2026)
Para mirar cómo se mueven: siete parcelas con los seis arquetipos en carriles, que arrancan solas al entrar (K otra vez,
J y U la variante; arriba de cada uno, su velocidad):
1. **Correr y frenar**: aceleran y al final sueltan, frenan apretando para atrás o se dan contra una pared.
2. **Saltar**: una valla de 0,3, 0,6 o 0,9 m, o una viga a la altura de la cabeza que no ven.
3. **Caer de alto**: se tiran corriendo de una plataforma de 2, 4 u 8 m.
4. **Llevar y tirar**: levantan un cubo de 63 cm, lo llevan y lo tiran con la carga elegida.
5. **Atajar**: les tiran un cubo a 5, 8 u 11 m/s, de frente, alto o al costado.
6. **Chocar**: de a dos (gordo y chico, musculoso y flaco alto, gordo atlético y viejo), de frente, en ángulo o contra
   uno quieto, con o sin cubo (Y).
7. **Esquivar barriles**: en zigzag a un costado y al otro de barriles en fila, separados (6,5 m) o juntos (4,5 m), por
   un camino fijo que no ve los barriles (la versión más simple de character-parametric, del 04/11). Corriendo casi
   todos se los llevan puestos; caminando, separados, pasan los seis.

Los maneja **`CharacterActions`**: aprieta los mismos botones que un jugador (moverse, correr, saltar, agarrar, tirar) y
las manos son las del jugador (un `InteractionController` con un ojo en la cabeza). Sigue un camino dado (`follow_path`, persecución pura) pero no lo busca ni esquiva nada. *Viene
de la parcela «Experimentos de locomoción» y de `ExhibitOperator` de character-parametric (unas 3.500 líneas entre los
dos), sin los pasillos de obstáculos, los botones, las sillas de la nave ni los controles.* Sus paneles, traídos de
allá: **F1** lo de todos los arquetipos (`LocomotionPanel`: caerse, llevar, tirar, el aire) y **F3** lo de cada arquetipo
(`LocomotionTuner`: caminata, pose, movimiento, equilibrio, salto y cuerpo, que también está en la fila Personajes).

Pruebas:
- `tests/people_look.tscn` (con ventana, unos 12 segundos): los seis en fila, sus cabezas de cerca, y caminando 3
  segundos (imprime cuánto anduvo cada uno y si quedó de pie). `--cabezas=0.29,0.28,…` prueba altos de cabeza.
- `tests/locomotion_look.tscn` (con ventana, unos 80 segundos): cada escena de la fila Locomoción sola, con capturas;
  imprime la velocidad máxima de cada uno, cuánto anduvo, si se cayó y si tuvo el cubo.
- `tests/sizes_check.tscn` (headless, un segundo): imprime cada medida de los seis y dónde cae cada hueso. **Si un cambio
  no debería cambiar a nadie, correrlo antes y después y comparar**.

Ver también [[red]].

## Qué se trajo y dónde se cortó
El 11/11/2026, de `D:\Godot\character-parametric` (último commit allá: `50a538ef`), pieza por pieza: el personaje, agarrar,
sentarse, los controles de mano, la red (`SessionManager`, `NetSpawner`, `CharacterSpawner`…, con GodotSteam), los
paquetes y su daño (hoy en `game/supplies/`), las partículas, el sistema de sonido, la depuración del personaje
(`DebugPanel`, `TunerPanel`, `PropertyTuner`) y la interfaz (`UIState`, la consola, la pausa, el menú de inicio). Se cortó
en la ciudad, el tránsito, la nave y sus paneles.

**La frontera** (`game/character_port/`: trece piezas vacías con los nombres de allá —`City`, `CarBody`, `CityMap`,
`WeatherTuner`, `Inspector`, `ShipStyle`…— para que lo traído compilara) **se borró el 13/11/2026**, con lo que las
llamaba: el mapa (F2), el clima (F6), el carnero, los ajustes de autos y de tránsito y el inspector vacío de
`PlayerController`, la cámara del tránsito en `CharacterSpawner`, `ModelBox` (el ida y vuelta con Blender de la silla,
sin modelos acá), `WorldSeeds` y `WorldSettings` (las semillas del día y la niebla de la ciudad), los sonidos de la nave y
la ciudad del catálogo, y los paquetes de ciudad que pedía la fila Multijugador. El panel de depuración del jugador
(sólo con sesión de red) pasó de la F1 a la **F9**, la primera de los paneles globales.

**Los comentarios** dicen «el usuario» donde allá decían «el dios del juego», y «la meca» donde describían estar adentro
de algo que se mueve (allá, la nave). Las notas de allá que nombran se citan como `character-parametric:docs/…`.

**Falta** (de la sesión de Personajes): partir `BoneInstantiator`, separar en `PlayerController` lo del jugador de lo de
prueba, y la pose de sostener algo con la mano (quedó a medias).

