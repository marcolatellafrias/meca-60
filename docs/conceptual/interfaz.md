# La interfaz: el lenguaje común

**Borrador** (17/11/2026). Primero que funcione; la capa estética, al final. Ver [[base]], [[progresion]].

## La decisión tajante (18/11/2026)
El usuario, ante la complejidad que crecía: **el menú se abre en la pantalla** (no se lee desde el costado, afuera; la
pantalla de la consola en el mundo muestra un placeholder pixelado), **fuera de la grilla de casillas y con
superpuestos**. Se queda lo **monocromo** (verde esmeralda sobre negro) y la idea general del ASCII: **lo que en color
serían grises o degradés, son tramas de puntos**. Una **letra retro que no sea de píxeles** (se probaron la nuestra de
trazos y la OCR-A). **Lo superpuesto se separa de lo de atrás** con una sombra de puntos, su propio fondo negro y un
borde doble; una ventana que pide algo, además, **atenúa todo lo de atrás con una trama negra**.
- **Lo elegido de la primera vuelta** (18/11/2026): **nuestra letra de trazos rectos**, dibujada en vector (no la OCR-A).
  **La barra de arriba: una raya** (la alternativa 1): el título a la izquierda, a la derecha el capitán, la plata y la
  cruz, sueltos, y debajo una raya a lo ancho; sin degradé ni barra llena.
- **En el juego** (18/11/2026): las terminales de la base (la armería y los contratos) ya van en este estilo. Lo común,
  en `game/ui/mono/`: `Mono` (los colores, las tramas, el superpuesto, la letra de trazos dibujada en 2D, los
  íconos), `MonoText`, `MonoButton`, `MonoTooltip`, `MonoIcons` (los de un bit), `MonoWindow` (una ventana
  superpuesta que atenúa lo de atrás), `MonoSlider`, `MonoCheck` y `MonoField`. El menú principal (con la ventana de
  «unirse con código»), las opciones y la pausa, también (`tests/menus_look.tscn`).
- Comprar y montar piezas a mano en la meca, los estantes y el receptáculo del techo quedan **de lado** por ahora: la
  complejidad explotaba (los controles de adentro cambiarían con alguien sentado; habría que acoplar la meca).

## El giro retro (18/11/2026)
El usuario: «quiero hacer un menú a lo viejo, a lo retro, que sea todo con píxeles… toda la pantalla… una grilla de
píxeles… las fuentes… los marcos». **Fondo casi negro y fósforo verde**, en tres brillos (encendido, medio y apagado)
más un relleno oscuro; la letra, la de trazos rectos **rasterizada** en su grilla de 4 × 6 (5 × 7 con el aire). Se
probó la armería a 320 × 180 y a 640 × 360 (agrandadas a 1280 × 720), y a 320 con líneas de barrido. **Lo único que no
es verde: la pintura de la meca**, que tiene colores; se repiensa (el aerosol y una plataforma al lado de la meca) más
adelante. Lo de abajo (el acento amarillo, los tamaños de letra) queda reemplazado por esto cuando se elija la
resolución.
- **Dos colores, nada más** (el usuario, 18/11/2026: «solo dos colores, negro y verde»): lo elegido va **invertido**
  (verde lleno, letra negra), lo que no se puede, **tramado** (un píxel sí, uno no), las líneas de fondo, punteadas.
  A **480 × 270** (cada píxel, 3 de pantalla: entre las dos que se probaron).
- **Sin cartel del mouse**: los superpuestos no se leen en estas máquinas. **Clic en una cosa lleva a su pantalla** (qué
  es, dónde va, qué hace, el precio y «comprar»), con «volver».
- **Íconos de un bit**, de 16 × 16, que se leen por la silueta y los huecos de adentro.
- **Pantallas encima de todo** por ahora (quizás diegéticas después). **Sólo el capitán compra, pone y firma.** El
  menú principal y la pintura, después.

## El lenguaje común
- **Una sola letra**: la de trazos rectos (`StrokeFont`, la de character-parametric). Hoy escribe sólo en el mundo 3D;
  para las pantallas hace falta un control 2D que la dibuje. Le faltan el `$` y los círculos de la dificultad.
- **Tres tamaños**: el título de la estación (uno por pantalla), el texto de listas y botones, y la ayuda gris.
- **Un solo color de acento**: el amarillo de las rayas de peligro.
- **Los botones**: normal, con el mouse encima, elegido, la acción principal (una sola, amarilla, abajo a la derecha) y
  lo que no se puede (gris; el porqué, con el mouse).
- **El marco de toda estación**: arriba, su nombre, la plata de la tripulación y el capitán; abajo, las teclas y la
  acción principal.
- **Una imagen se entiende antes que un texto**: cada cosa que se compra tiene su **ícono en pixel art** (24 × 24, en
  color, con contorno oscuro: el estilo 3 de las maquetas). Los de hoy son placeholders hechos por código; después, a
  mano o capturas de los modelos con el fondo borrado.

## Las estaciones (primera versión)
- **El menú principal**: crear partida, unirse con código, opciones, salir.
- **La esclusa**: sólo un cartel arriba («esperando tripulación», quién está, el código para invitar). Sin explicar el
  botón: se dan cuenta solos.
- **Contratos**: la lista (dificultad, jefe, paga, afijos) y el detalle con el jefe en 3D. Bien así (el usuario,
  17/11/2026); cambios menores después.
- **Armería** (la variante B): la tienda en grilla con ícono, nombre y precio; la meca dibujada con sus huecos y el
  depósito de la sucursal, **sólo con íconos** (sin nombres); la descripción, en el cartel del mouse. Se arrastra para
  comprar, poner y sacar.
- **Cosméticos y pintura**, dos pestañas:
  - **Cosméticos**: **el mismo sistema que la armería** (el usuario: «así de paso tenemos un lenguaje unificado»): la
    tienda en grilla, la meca con sus huecos de cosméticos (el banderín, la cabina, los propulsores) y el depósito.
  - **Pintura**: se elige qué superficie, se pinta en 2D por píxeles (lápiz, balde, goma, grosor) con un selector de
    color. Hay que replantearlo si la meca es la redonda. **Sin terminaciones** (mate, satinado, gastado: no).
- **Casilleros y cuadro del empleado del mes**: no van en la primera versión.

## Abierto
- Qué hacen los que no son capitán en las estaciones (¿proponen?).
- Los íconos y las imágenes de verdad.
