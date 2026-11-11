# Meca

Juego cooperativo (de 1 a 4 jugadores) de una **meca gigante manejada desde adentro** contra jefes (bichos) en una
arena. Cada jugador maneja una parte de la meca desde su puesto (piernas, brazos…); cuando algo se rompe hay que
reacomodarse, salir afuera a reparar o ir a buscar recursos. Entre peleas, un hangar con oficina: contratos,
reparaciones con plata y cargar la meca. Hecho en **Godot 4.5** (GDScript), física con **Jolt**. Empezado el 11/11/2026;
hoy es un **boceto para probar la idea**, de a uno.

Varias piezas vienen de `D:\Godot\taxi` (el sandbox, el que camina, el menú de pausa, el lanzador de ventana), que a su
vez las trajo de `D:\Godot\character-parametric`.

## Decisiones tomadas
- Sólo contra jefes, no contra otras mecas (una sola cosa bien). Un modo arena entre jugadores, quizás después.
- Los jefes: **pocos arquetipos hechos a mano**, con **las partes por semilla**, **partes que se rompen** y **afijos**
  encima. Nada de piezas del bicho en la meca ni de sistema Némesis por ahora.
- La meca se arma según cuántos jugadores hay (más adelante, también por semilla: ruedas en vez de piernas, otros
  brazos). Sin cabeza.
- Entre peleas: el hangar como oficina, los contratos, los arreglos que cuestan plata y cargar la meca (con espacio
  limitado, sin sistema de peso).

## Cómo se prueba hoy
En el sandbox, la fila **Meca** («Pelea de prueba»): **U** sube a la meca, al piso de las piernas. **E** se sienta en
el puesto más cercano y se levanta; parado en el montacargas, **E** lo manda a la otra punta. Sentado:
- Piernas: W/S camina, A/D gira, Shift se afirma.
- Brazos: el mouse apunta, clic izquierdo el puño de resorte, clic derecho el cañón.
- Vigía: una cámara de afuera que gira con el mouse.
- Desde cualquier puesto (para probar de a uno): flechas caminan, B se afirma, F puño, G cañón.
- **N** otro bicho, **R** otra arena. **V** es el modo creativo del sandbox (volar atravesando).

## Dónde va cada cosa
Por feature: `game/<feature>/` (código y escenas juntos), los tests en `tests/`.
- `game/mech/` — **la meca**: `Mech` (la raíz en el suelo, la marcha, el equilibrio y la caída, los puestos y las
  teclas), `MechTorso` (el torso de tres pisos con la escalera de incendio atrás), `MechSeat` (un puesto con su nivel de
  equilibrio y su cámara), `MechLift` (el montacargas), `MechLeg` (una pierna, sólo dibujo), `MechArm` y sus brazos
  `MechFist` (el puño de resorte) y `MechCannon` (con su bala `MechShell`), `MechHud` (lo de pantalla para probar) y
  `Clay` (la arcilla de los bocetos).
- `game/beast/` — **los bichos**: `TestBeast` (el bicho de prueba: partes por semilla, equilibrio, caerse y levantarse)
  y `BeastPart` (una parte que se rompe; todo lo que tiene `take_hit(amount, direction, push)` recibe golpes).
- `game/arena/` — `TestArena` (el redondel con edificios, la meca y el bicho) y `MechTestArchetype` (la fila Meca).
- `game/sandbox/` — el sandbox de parcelas (`DesignSandbox.categories()` agrega filas). Teclas del sandbox: WASD,
  espacio, shift, Ctrl, R, C, V, Escape; no repetirlas. Sentado sólo valen las de la meca.
- `game/ui/` — el menú de pausa (autoload `PauseMenu`, Escape) y sus Opciones (`GameOptions`, `user://opciones.cfg`).

## Verificación
- **Todo Godot con ventana se lanza con `tools/godot_ventana.sh`** (no le roba el foco al usuario; carpeta de los
  agentes `D:/Godot/agentes/meca`).
- **Nunca cerrar un Godot que no sea de los agentes**: sólo los de `--path D:/Godot/agentes/...`.
- Chequeo de compilación: `godot --headless --path . --editor --quit`; los warnings son errores.
- `tests/mech_check.tscn` (headless, o con ventana `-- --salida=<carpeta>` para capturas): se sube, se sienta, camina,
  pega, dispara, tira al bicho y hace caer a la meca.
