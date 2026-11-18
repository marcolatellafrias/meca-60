# La base en el sandbox

`game/base/` (`BaseLayout`, `BaseHatch`, `BaseAirlock`, `BaseSlideDoor`, `BaseSettings`, `BasePanel`, `BaseArchetype`) · fila **Base** (Mundo) · el diseño, en [[base]] · ver [[filas]]

La sucursal en arcilla, **sin estética**: el plano de [[base]] armado de cajas, para recorrerlo con la meca y a pie.
Lo estético de cada cosa lo agrega el usuario después.

## Qué hay (a escala humana, 17/11/2026)
El plano de la esclusa de [[base]], para la meca jaula (≈ 7 m). *Hasta el 17/11/2026 era la base de la meca grande:
el elevador de 24 m, la nave de 22 m y el ascensor de personal metido en la pared, que la esclusa reemplaza.*
- **Un solo piso, todo al mismo nivel**, en L: el elevador (10 × 10 m; lo marcado, 9 m) y el gimnasio (14 × 10 m) en
  fila, y debajo del gimnasio la franja de las consolas (6 m de fondo y 4 m de alto). La nave, de 12 m, con **techo**;
  adentro, lámparas colgadas.
- **El elevador**: un cuadrado del piso con el borde amarillo a rayas. Ahí duerme la meca jaula, mirando al gimnasio.
  Todavía no sube.
- **La compuerta del techo** (`BaseHatch`), sobre el elevador: dos hojas que se corren hacia los costados. La abre y la
  cierra la **G** de la parcela.
- **La línea de peligro** entre el gimnasio y la franja.
- **La bolsa**: 1,8 m de diámetro, de 1 a 4,6 m de alto (se le pega con la meca agachada), colgada de una viga. Fija,
  con su colisión.
- **La franja usa sus dos caras libres** (la del gimnasio es la línea de peligro y la de la punta, la esclusa):
  - **la pared bajo el elevador**: los contratos, al lado de la meca;
  - **el fondo**, desde ahí: la armería, los cosméticos y la pintura, el cuadro del empleado del mes y los casilleros
    que entren, hasta la esclusa.
- **La esclusa** (`BaseAirlock`, con `BaseSlideDoor`), la sala de espera, en la punta de la franja: **un cuadrado del
  lado del fondo de la franja y de su alto**; si cambia el fondo, cambia ella. Dos bancos, una baliza roja que gira y el
  cartel «esperando tripulación».
  - **El botón de adentro** (un botón de compuerta de los tableros, `ButtonArchetype.for_control`), al lado de la
    compuerta de adelante: la luz pasa a verde, un poco de vapor, la compuerta se abre y a los 6 s se cierra **para
    siempre** («cerrada»).
  - **La compuerta de atrás** es la de «afuera». **Para probar en el sandbox** se abre con un botón de afuera (5 s),
    así se entra caminando; la **X** de la parcela rearma la esclusa.
  - Todavía no se aparece ahí, ni la meca se arma con los que son: eso es del flujo de la partida.
- **Lo fijo** (`PhysicsLayers.mark_fixed`): el piso, las paredes y los bolsillos de la compuerta. Sin eso, la meca
  jaula (cinemática) se cae por el piso.

## Las medidas
En `BaseLayout`, en metros sobre el plano (`at(x, z, alto)` pasa a la parcela).
- **Se mueven con el F1** de la fila (`BasePanel`, perillas en `BaseSettings`; el usuario, 17/11/2026: «tengo que
  experimentar con distintas perillas, distintas escalas… se siente un poco claustrofóbico»):
  - **el alto de la nave** (8 a 25 m);
  - **el fondo de la nave** (6 a 20 m), que es también **el lado del elevador**: siempre cuadrado, crece hacia su lado
    y la franja queda alineada con él;
  - **el ancho de la franja** (11 a 30 m), que es también el largo del gimnasio;
  - **el fondo** (4 a 12 m) y **el alto** (3 a 10 m) **de la franja**, también los de la esclusa;
  - **dónde cuelga la bolsa**: al medio del gimnasio (para dar vueltas pegándole) o en la punta, contra la pared con
    2,5 m libres (para pegarle de un lado).

  Al guardar, la base se vuelve a armar en su lugar (`BaseLayout.rebuild`) y la meca, nueva, vuelve al centro del
  elevador (`BaseArchetype.place_mech`). Lo guardado, `game/base/base_humana.tres`, es del usuario: no va al
  repositorio (el de la meca grande, `base_settings.tres`, quedó de lado).
- **El fondo de la franja se llena solo**: la armería, los cosméticos y el cuadro en fila desde la pared bajo el
  elevador, y los casilleros, los que entren hasta la esclusa.
- La bolsa, de 1,8 m de diámetro, cuelga de 1 a 4,6 m: se le pega con la meca agachada.
- La parcela se mide con todo lo más grande.
- Los paneles F2 a F4 son los de la meca jaula, para modificarla desde la base.

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
`tests/base_look.tscn` (con ventana, unos 10 s): desde arriba con la compuerta del techo abierta, adentro de la esclusa
(cerrada y, después de apretar el botón, abierta), lo que se ve al salir, la franja con los contratos y la meca desde el
gimnasio; y otra vez con otras medidas y la bolsa en la punta (lo que hace el F1 al guardar, sin guardarlas).
`tests/base_terminals_look.tscn` (con ventana, unos 5 s): la armería con unas compras hechas y lo que dice con el mouse
encima, y los contratos con uno firmado.
`tests/armory_parts_look.tscn` (con ventana, unos 10 s): todos los componentes juntos, y después uno por uno, de cerca.
*Hasta el 17/11/2026, `tests/armory_dressed_look.tscn` y `armory_dressed_movie.tscn` mostraban la meca grande con todo
puesto (`ArmoryParts.dress`) y sus variantes de cabina; se borraron con ella (commit 0bcaeaf). `ArmoryParts.dress` quedó
sin quien la llame: viste los brazos discretos y las piernas de cualquier meca (un brazo con músculos no se viste, y el
del cañón de la jaula, sin mano, no la pierde ni la engorda), a escala de la meca grande.*

**La meca de la base es la jaula** (`CageMech`, con el equipo de su fila) desde el 17/11/2026; antes, la discreta de la
meca grande. Los paneles de la jaula están en la fila (F2 a F4).
