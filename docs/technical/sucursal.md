# La base en el sandbox

`game/base/` (`BaseLayout`, `BaseHatch`, `BaseSettings`, `BasePanel`, `BaseArchetype`) · fila **Base** (Mundo) · el diseño, en [[base]] · ver [[filas]]

La sucursal en arcilla, **sin estética**: el plano 6 de [[base]] armado de cajas, para recorrerlo con la meca y a pie.
Lo estético de cada cosa lo agrega el usuario después.

## Qué hay
- **Un solo piso, todo al mismo nivel**, en L: el elevador (24 × 24 m) y el gimnasio (36 × 24 m) en fila, y debajo
  del gimnasio la franja de las consolas (12 m de fondo y **5 m de alto**, a escala de persona: sobre su borde abierto,
  la pared de la nave baja hasta ahí, como un dintel). Debajo del elevador, pared. La nave, de 22 m, y **techo**; adentro,
  cinco lámparas colgadas (el sol no entra).
- **El elevador**: un cuadrado del piso con el borde amarillo a rayas. Ahí duerme la meca, mirando al gimnasio.
  Todavía no sube.
- **La compuerta del techo** (`BaseHatch`), sobre el elevador: dos hojas que **se corren hacia los costados**, como una
  puerta de ciencia ficción, cuando empieza una partida; cada una se guarda en su bolsillo, una caja sobre el techo (la
  de afuera, metida en la roca). Por ahora la abre y la cierra la **G** de la parcela.
- **La línea de peligro**, rayas amarillas y negras en el piso, entre el gimnasio y la franja: no hay pared ni vidrio.
- **La bolsa**: un cilindro de 5,2 m de diámetro, de 7 a 15 m de alto, colgado de una viga. **Fija por ahora**, con su
  colisión, para pegarle; la física, después.
- **Las consolas**, contra la pared de la franja: una caja con la pantalla inclinada y su cartel. Los contratos
  (6 m), la armería (4,5 m), los cosméticos y la pintura (4,5 m). Todavía no hacen nada.
- **Los personajes**: seis casilleros, el cuadro del empleado del mes al lado, y **el ascensor de personal**, una jaula
  metida en un hueco de la pared de la punta. **El hueco es sólo de su alto** (3,4 m): arriba sigue la pared. Es una
  ilusión de continuidad, no un pozo.

## Las medidas
En `BaseLayout`, en metros sobre el plano (`at(x, z, alto)` pasa a la parcela).
- **Se mueven con el F1** de la fila (`BasePanel`, perillas en `BaseSettings`): **el alto de la nave** (16 a 45 m), **el
  fondo de la franja** (6 a 30 m) y **su alto** (3,5 a 20 m). Al guardar, cada base armada se vuelve a armar en su
  lugar (`BaseLayout.rebuild`; la meca se queda). Lo guardado, `game/base/base_settings.tres`, es del usuario: no va al
  repositorio.
- Lo demás (el elevador, el largo, el hueco del ascensor de personal, la bolsa), en las constantes de `BaseLayout`.
- La parcela se mide con la franja más honda (30 m): con una menos honda, la base se arrima a la pared del fondo.
- Los paneles F2 a F4 son los de la meca propia (como en los jefes), para modificarla desde la base.

## Las terminales (15/11/2026)
La armería y los contratos se usan: se mira la consola, se aprieta **E** y se abre su pantalla; **E o Esc** la cierra.
Pedido del usuario: «vos te acercás, apretás E y se te abre». La consola de cosméticos y pintura todavía es de adorno.
- **`BaseTerminal`** (un `ActivatableInteractable`) cuelga del cuerpo de cada consola, que es lo que se contornea.
- **`TerminalScreen`** es la base de las pantallas: una sola abierta a la vez, y mientras está abierta el mouse queda suelto
  (`UIState`, capa `base_terminal`).
- **`BaseState.current`** guarda lo de la sucursal: la plata de la tripulación (arranca con $2500), **el depósito de la
  sucursal**, lo que tiene puesto la meca y el contrato firmado.
  - Vive mientras corre el juego: no se guarda a disco.
  - No pasa por la red: compra el que abre la terminal. *Después, sólo el capitán* (ver [[progresion]]).
- **La armería** (`ArmoryScreen`, `ArmoryCatalog`) tiene tres partes:
  - A la izquierda, **la tienda**. Hay un ejemplar de cada herramienta de brazo y de cada arma de espalda; las placas se
    compran cuantas veces haga falta.
  - Al medio, **la meca dibujada de atrás** (`MechDrawing`), con sus diez huecos encima: el puño de cada brazo (nunca
    vacío: se cambia soltándole otro encima), la herramienta que se le agrega a cada puño, las dos armas de la espalda y
    las placas de cada brazo y de cada pierna. Lo que se vende, en [[progresion]].
  - A la derecha, **el depósito**.
  - **Cómo se usa:**
    - **Comprar:** arrastrar de la tienda a un hueco (se compra y se pone) o al depósito. Doble clic también compra al
      depósito.
    - **Poner:** arrastrar del depósito a un hueco. Lo que había en el hueco vuelve al depósito.
    - **Sacar:** arrastrar del hueco al depósito.
    - **Cambiar de lado:** arrastrar de un brazo al otro.
    - Con el mouse encima de algo se ve qué es, qué hace y cuánto cuesta.
  - El depósito es la respuesta a la duda del usuario: dónde queda lo que se saca si la meca no tiene inventario. Es de la
    sucursal, no de la meca.
  - **Los nombres, los precios y los textos son de prueba**, y lo que se pone todavía **no cambia la meca** de la
    parcela.
- **Los contratos** (`ContractsScreen`, `ContractsCatalog`):
  - Una lista a mano con los jefes que hay: el peleador y las maquetas. Cada contrato tiene su dificultad, su paga y
    afijos de prueba.
  - **«Firmar»** deja firmado el contrato elegido.
  - **«Salir a la arena»**, con un contrato firmado, abre la compuerta del techo. Todavía no hay arena detrás.

## Los componentes en arcilla (15/11/2026)
Lo pidió el usuario: «empecemos a hacer maquetas de clay de todos los componentes».
- **`ArmoryParts`** tiene una maqueta por cosa que vende la armería, a la escala de la meca: el antebrazo de `MechBody`
  y la mano de `MechHand`.
- **Lo del brazo** va sobre un antebrazo con una boca más ancha en la punta.
  - Por ahí sale el puño cerrado o, con el puño guardado adentro, la herramienta. Nunca los dos a la vez.
  - Las herramientas van en el eje del brazo, exageradas: la mecha del taladro es ancha y corta, el doble de ancha que el antebrazo, el cañón
    de energía es un solo cilindro grande, gris oscuro, y la sierra es un disco de 6 m en una horquilla.
  - El puño pesado es la misma mano, un 30 % más grande, con las falanges más gruesas y más largas, y un cono en cada
    nudillo.
- **Lo de la espalda** va sobre un pedazo del techo con su torreta.
- **Cada placa** son tres caras del prisma de ocho del miembro, gruesas y bien despegadas (que no se confundan con él): arriba del antebrazo, o al frente de la
  canilla. El torso, por ahora, sin placa.
- **`ArmoryParts.dress`** viste una meca armada con un `loadout` (los huecos de `BaseState`), para mirarla con todo
  puesto. Pone:
  - las placas en los dos tramos de cada miembro (el brazo y el antebrazo, el muslo y la canilla), giradas de a octavo
    de vuelta hasta mirar afuera en los brazos y al frente en las piernas;
  - el puño pesado sobre la mano de la meca, o la herramienta afuera con la mano escondida;
  - las armas de la espalda sobre el techo.

  Toca adentro de los brazos y las piernas, así que es sólo para mirar: la armería todavía no viste la meca de la base.
- En el sandbox, en la fila **Componentes de la armería** (`ArmoryPartsArchetype`), numeradas y en tres filas.

## Para mirarla
`tests/base_look.tscn` (con ventana, unos 8 s): cuatro capturas, desde afuera con la compuerta abierta, desde la
franja de las consolas, desde el gimnasio hacia la compuerta, y otra vez desde afuera con otras medidas (lo que hace el
F1 al guardar, sin guardarlas).
`tests/base_terminals_look.tscn` (con ventana, unos 5 s): la armería con unas compras hechas y lo que dice con el mouse
encima, y los contratos con uno firmado.
`tests/armory_parts_look.tscn` (con ventana, unos 10 s): todos los componentes juntos, y después uno por uno, de cerca.
*Hasta el 17/11/2026, `tests/armory_dressed_look.tscn` y `armory_dressed_movie.tscn` mostraban la meca grande con todo
puesto (`ArmoryParts.dress`) y sus variantes de cabina; se borraron con ella (commit 0bcaeaf). `ArmoryParts.dress` quedó
sin quien la llame: viste los brazos discretos y las piernas de cualquier meca (un brazo con músculos no se viste, y el
del cañón de la jaula, sin mano, no la pierde ni la engorda), a escala de la meca grande.*

**La meca de la base es la jaula** (`CageMech`, con el equipo de su fila) desde el 17/11/2026; antes, la discreta de la
meca grande. Los paneles de la jaula están en la fila (F2 a F4).
