# La base común de las mecas

Lo que comparten **la meca propia** y **las mecas enemigas (los jefes)**: `BalanceBody`, en `game/balance_body/`
(separada de `Mech` el 13/11/2026; ver [[estructura]]). La meca propia hereda de ella; un jefe también.
Esta nota junta lo acordado, para quien haga la meca y quien haga los jefes. Hoy la heredan la meca jaula y su meca de
práctica, las dos con el motor discreto (abajo; ver [[meca-jaula]]); a la meca, los jefes le pegan por su
puerta (`hit`, `shove`, `knock_down`; ver [[pelea-jefes]]). *Hasta el 17/11/2026 la heredaban también las de la meca
grande, borrada ese día (commit 0bcaeaf). Hasta el 18/11/2026 había también un cuerpo físico, EL PÉNDULO (la caja la
movía Jolt sobre un palo hasta un punto de apoyo que la seguía; se caía pasado un ángulo y se levantaba con toberas:
`BodyMoves`, `BodyNozzles`, `BodySettings`); lo usaba sólo la meca de práctica y el usuario lo borró en la limpieza del
esqueleto («Borrarlo»). Está en el commit d09b964, con su nota (`pendulo`).*

## Qué es
**Un solo cuerpo** que se inclina, pierde el equilibrio y recibe golpes. Nada más. El usuario (13/11/2026): «los
jefes van a heredar una clase abstracta que comparten con la meca propia, que es todo el sistema de equilibrio… un
cuerpo físico que se inclina y pierde equilibrio»; y a la vez «no quiero correr el riesgo de limitarme por compartir
demasiado… las mecas de jefes tal vez puedan llegar a tener cosas más locas».

## Qué NO es (son piezas que cada uno elige o reemplaza)
- **El medio de moverse**: dos piernas, cuatro, ruedas, o volar.
- **Los brazos** o lo que tenga para pegar.
- **La cabina** y el marco para caminar adentro: sólo la meca propia.
- **Quién la maneja**: las teclas, las consolas, o el cerebro de un jefe. Todos escriben «lo que se le pide».

Por eso conviene armarla **de piezas y no como una clase abstracta larga**: un jefe raro arma lo suyo sin heredar nada
que lo limite.

## Para tener en cuenta al diseñarla
- **Las piernas no siempre salen de la pelvis.** En algunos van **en el cuerpo físico mismo**: una araña larga con las
  patas saliendo de los costados, en vez de abajo (el usuario, 13/11/2026). Hoy `BodyLegs` cuelga las dos piernas de una
  pelvis debajo de la caja; la pieza de las piernas tiene que poder decir **de dónde sale cada pata** —de una pelvis o de
  puntos del cuerpo— y cuántas son. «Es un detalle mínimo, pero se puede estandarizar.»
- **La caja la mueve su motor** (`KinematicMover`), nunca a mano: lo que la empuja pasa por su puerta (`knock_back`,
  `shove`, `carry`, `knock_down`).

## Cómo se usa
Un cuerpo nuevo hereda de `BalanceBody`, pone su `size` y su masa en `_init`, y redefine tres ganchos: `_build` (arma sus
piezas: cerebro, armas, otro medio de moverse), `_think` (al empezar cada paso escribe lo que se le pide) y
`_after_step`. Puede llevar sus propias perillas de moverse (`kinematic_knobs`, un `KinematicSettings`).

**Lo que falta**: la pieza de las piernas todavía es una sola, `BodyLegs` (dos patas desde una pelvis). Las patas que
salen del cuerpo, las cuatro patas o las ruedas son otra pieza que hay que poder elegir en `_build`; hoy el cuerpo arma
siempre `BodyLegs`.

## Quién
Es de la sesión de la meca; la de jefes la usa y le pide cambios.

## El motor discreto — `KinematicMover` (13/11/2026)
**Al cuerpo lo mueve el controlador de personaje del motor**, con movimiento discreto. Es como se mueven la meca jaula
y la de práctica; los jefes lo usan por su puerta. Salió del laboratorio cinemático (un cubo
contra cajas sueltas, borrado el 17/11/2026 con la meca grande; el usuario: «un sistema simple, barebones, sólido y que
use las cosas del motor, y no reglas inventadas»). *Esta parte vivía en las notas de la meca cinemática y del
laboratorio, borradas ese día; están en el commit 0bcaeaf.*
- **La caja queda congelada** y la mueve **`KinematicMover`**, un `CharacterBody3D` (`move_and_slide`): se le da una velocidad, y él frena y se
  desliza contra paredes y esquinas, sabe si está en el piso y se sale solo si queda metido en algo.
- **Contra lo fijo del mundo, un cilindro** que envuelve la caja y lo que sobresale adelante (`outline_extra`), y mira
  **sólo la capa de lo fijo** (`PhysicsLayers.FIXED`). Un piso o una pared que no esté marcado como fijo, la meca lo
  atraviesa: el sandbox lo marca; un test que arma su propio piso tiene que marcarlo (`PhysicsLayers.mark_fixed`).
- **Contra lo suelto**, el motor sin reglas extra: la caja empuja, y **los pies con choque** (`StompFeet`), que siguen a
  los de las piernas, patean de costado. **Lo que queda debajo de un pie que baja, o de la caja al agacharse, se
  achata**: suena, larga polvo y desaparece. Los personajes todavía no.
- **Movimiento discreto, en metros y segundos** (`KinematicSettings`; cada cuerpo puede llevar las suyas,
  `kinematic_knobs`: la jaula, en su F1): una velocidad y el tiempo para llegar a ella; giro con tope; salto sólo para
  arriba; vuelo con su barra; dash (Shift con dirección) en el piso y en el aire con su barra; agacharse.
- **La altura**: la de las piernas (el F2).
- **Lo que la mueve sin manejarse** (lo pidieron los jefes): `shove` la corre su motor (también el revoleo) y
  `knock_down` la tira y se levanta; tirada es intocable (`untouchable`).
- Para ponerla en otro lugar sin barrer el camino: `put`. Para manejarla desde un test o un cerebro: `scripted` (en la
  meca).

**Lo que se aprendió armándolo** (con el cubo del laboratorio):
- Con la física sincronizada, poner la posición del cuerpo desde afuera no alcanza: el cuerpo la pisa con la suya. Por
  eso se pone con `put`.
- **Un cuerpo cinemático que se pone en otro lugar barre lo que hay en el medio**, a la velocidad de ese salto (los pies
  cruzaban 22 m en un paso y las cajas salían a 430 m/s). Para ponerlos en un lugar se apaga la sincronización un
  instante (`place_now`, `put`); y en el aire los pies se juntan debajo de a poco.
- **Un cuerpo entra a la física donde está al agregarlo al árbol**: los pies nacen en su lugar, no en el origen.
- **Una prueba de movimiento que arranca tocando algo no lo cuenta como choque**: el cilindro se prueba levantado 5 cm.
- **Las cajas nuevas no pueden nacer encimadas**: el motor las separa a lo bruto.
- **Un «pruebo y deslizo» escrito a mano pelea con el motor** (en una esquina quedaba 1 cm adentro y de ahí atravesaba
  el edificio): con `CharacterBody3D` y la capa de lo fijo, desaparece.

## Los paneles de perillas, todos iguales — `KnobsPanel` (13/11/2026)
El usuario: «borraría lo de probar y dejaría solamente guardar. Y que cuando guarde se regeneren las mecas… un solo
sistema robusto». *Vivía en la nota de la meca grande, borrada el 17/11/2026.*
- **Se mueve un borrador.** Nada cambia en vivo con la meca en movimiento.
- **Un solo «Guardar»**: el borrador pasa a las perillas, se escribe a su archivo (del usuario, no se sube) y **se
  aplica**: rearma todas las mecas (`Mech.rebuild_all`). «Volver a lo guardado» hace lo mismo con lo del archivo.
- **Cada número, un solo dueño.** **La altura de la caja no es una perilla**: sale del cuerpo, del largo y lo estirado
  de las piernas (el F2), y la meca la toma al armarse (`BalanceBody.hover`, de `MechBody.WAIST`). **El paso**
  (`LegSettings`, F4) es el de piernas medianas, y las piernas lo escalan con su largo al leerlo.
- **Dónde nace parada** una meca lo dice un solo lugar, `Mech.standing_height()`.

## Las curvas de los movimientos discretos (14/11/2026)
`MoveCurve` y `MoveRamp`, en `game/balance_body/`. Las escribió el módulo Jefes para rodar hecho bola; son de la base
común para que las use todo movimiento discreto (el usuario: «si yo hago un dash… y lo tengo activado con easing, que
haga easing»).
- **Una curva** (`MoveCurve.Shape`: lineal, arranca lento, frena al final, o las dos) es la forma en el tiempo de un
  movimiento que ya tiene sus números.
- **De un tramo** (el dash, el salto, una carga: tantos metros en tantos segundos): `MoveCurve.velocity` da la velocidad
  en cada momento.
- **Sostenidos** (caminar, rodar): `MoveRamp` sube hacia la velocidad pedida en un tiempo, con su curva, y baja al
  soltar en otro, con la suya. Es continua: cambiar de pedido a mitad de camino no salta. Una bajada larga es la inercia.
- Hoy `MoveCurve` la usa el dash de la meca. `MoveRamp` la usaba el jefe bola para rodar (borrado el 15/11/2026); la
  va a usar el Luchador de orugas. Falta que las usen el salto y caminar de la meca.
