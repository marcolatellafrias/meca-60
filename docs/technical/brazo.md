# Los brazos

> **Cambio de rumbo (22/11/2026):** los brazos ya no son físicos. `MuscleArm`, `StrikeSettings` y el golpe que barría la
> punta se borraron (están en el commit `5238ff8`). **Lo que pega es la zona de cada habilidad** (`MechSkills`). Lo de abajo
> sobre músculos, choques y barrido queda como historia.

Ver [[filas]] y [[meca-jaula]] (la meca que los lleva: el cañón en uno discreto, el palo en uno con músculos).
*Hasta el 17/11/2026 eran también los dos caminos de la meca grande (la Meca discreta y la Meca física, con la fila
Brazo); se borraron con ella y están en el commit 0bcaeaf.*

## Lo que se le pide a un brazo — `MechArm` (`game/mech/`)
Escrito una vez, para los dos caminos: **las posturas** (normal, cubriéndose, recogido), **las piñas** (unos pocos puntos
por donde pasa el puño, con sus tiempos: se arma, pega, se queda, vuelve), **la pose** (el codo y la muñeca por IK,
`MechBody.arm`) y **la mano**, montada por regla.

## El brazo discreto — `PoseArm` (`game/pose_arm/`) · el del cañón de la jaula
Se dibuja en la pose pedida, sin cuerpos: va exacto, no se traba y atraviesa lo que haya. **Mientras pega**, el puño
barre su camino en el mundo (la regla del puño de la vieja meca de pelea) y a cada cuerpo suelto que toca le da, una vez
por piña, **un impulso** en el punto del golpe: su velocidad por lo que pesa el puño (7 t; perilla de `PoseArmSettings`, F3). A otra meca la empuja en su caja y su
péndulo decide. Medido: un directo conecta a 42 m/s e inclina al cubo 7°, sin tirarlo. Lo fijo no lo frena.

## El brazo con músculos — `MuscleArm` (`game/muscle_arm/`) · el del palo de la jaula

El primer paso de los brazos físicos de la meca, solo en su fila para tunearlo: un torso fijo en el aire con **un**
brazo. La idea es la de PuppetMaster: **la IK dice la pose; el cuerpo físico la persigue con músculos**. *La fila
(Brazo, `MuscleArmArchetype`: el torso fijo, el bloque y la pared) se borró con la meca grande el 17/11/2026; sus
perillas (`MuscleArmSettings`) son la pestaña «Con músculos» del F3 de la jaula.*

## Las dos capas
- **La pose que se pide**: dónde quiere el puño (en guardia, a lo largo de una piña, o donde lo lleva el mouse) y, de
  ahí, el codo y la muñeca: la IK del cuerpo de la meca (`MechBody.arm`), la misma del dibujo.
- **El cuerpo físico**: el **brazo** y el **antebrazo** (con la mano en la punta, la de toda meca) son
  cuerpos sueltos. **El hombro es una bola** y **el codo una bisagra**, como los de verdad. Un **músculo** por
  articulación, con resorte, freno y **fuerza tope**:
  - el del hombro gira el brazo hacia la orientación pedida, incluido el giro sobre su largo, que es el que lleva el
    antebrazo de costado;
  - el del codo sólo dobla, sobre el eje de su bisagra, y empuja al brazo para el otro lado.

## Lo que sale solo
- **Se traba**: contra algo fijo se queda ahí, empujando con su fuerza, y cuando se le pide volver, vuelve.
- **Cede**: si le pegan, se corre y vuelve a su lugar.
- **La fuerza de la piña** es la velocidad a la que llegó la mano: el bloque sale según eso.

## Cómo se probaba (la fila Brazo, borrada el 17/11/2026)
- **1** directo · **2** gancho · **3** uppercut · **4** desde arriba. Cada piña son unos puntos por los que se pide
  que pase el puño, con sus tiempos (se arma atrás, pega, se queda un instante y vuelve a la guardia).
- **N** pone una pared donde está el bloque (y lo guarda), o la saca. **J/K**, una bola liviana o pesada contra el brazo. **R** vuelve a armar todo.
- **F1** las perillas (`MuscleArmSettings`): el resorte, el freno y la fuerza del músculo; cuánto más rápidas las piñas. Se guardan («Guardar», «Volver a lo guardado»; ver `KnobsFile`), en un archivo del usuario que no se sube.
- **A mano** ([[poseer]]: mirándolo, **O**): el mouse lleva la mano de costado y arriba y abajo, W/S adelante y atrás.
- `tests/muscle_arm_look.tscn` (unos 30 s, sin el sandbox).

## Lo medido (12/11/2026)
| | |
|---|---|
| En guardia | quieto, la mano a 7 cm de donde se la pide (lo que cede por su peso) |
| Directo | la mano llega a 53 m/s; el bloque de 6 t se corre 2,4 m |
| Gancho / uppercut | 54 / 66 m/s (no le pegan al bloque donde está) |
| Desde arriba | 107 m/s: llega con látigo, demasiado |
| Contra la pared | trabado a 3,6 m de lo pedido; después vuelve a la guardia |
| Un empujón de 18 m/s al antebrazo | cede 0,6 m y vuelve |

## Dos cosas que hubo que aprender
- **La resistencia a girar es muy distinta según el eje**: de punta a punta, grande; sobre su largo, casi nada. El
  músculo mide su fuerza con la de cada eje. Con una sola para todos, la pieza giraba sobre sí misma al tope del motor.
- **El codo tiene que ser bisagra.** Con una bola, el músculo del antebrazo hacía girar al brazo sobre sí mismo sin que
  nada lo frenara.

## La mano
`MechHand` (en `game/mech/`), la de toda meca. Dos posturas: **abierta** (en guardia y a mano) y **el
puño** (mientras tira una piña), con las falanges dobladas sobre la palma y el pulgar encima; pasa de una a otra en 0,16
s, con easing. Hacia qué lado cierran los dedos lo dice quien la arma: acá, hacia donde dobla el codo; en la meca
péndulo, hacia adentro del cuerpo. Para mirarla: `tests/hand_look.tscn`.

## Las posturas
Dónde descansa el puño: **normal** (el brazo al costado, la mano abierta), **cubriéndose** (el puño cerrado adelante) y
**recogido** (la mano contra el hombro, cuando lo que lo sostiene se cae). Pasa de una a otra de corrido; después de una
piña vuelve a la que tenga. *En el banco (la fila Brazo, borrada), **5** cambiaba entre normal y cubriéndose.*

## Lo que lleva en la punta, y la placa — `ArmTip`, `ArmLoadout` (`game/mech/arm_tips/`)
Desde el 16/11/2026 (el usuario: «unificar el sistema de los brazos, ver qué cosas se equipan»; que **cada brazo elija**
discreto o con músculos) **cómo se mueve un brazo y qué lleva en la punta son cosas aparte**. La punta es un nodo que el
brazo monta en la punta del antebrazo (`MechArm._mount_hand`) y llama en cada paso; se monta igual en uno discreto que en
uno con músculos:
- **Puño común** (`ArmTip`, la de siempre: la mano) · **puño pesado** (`HeavyFistTip`, el de la armería) · **palo
  eléctrico** (`PoleTip`: el puño pesado siempre cerrado agarrándolo; sólo se ve).
- **Taladro** y **sierra** (`DrillTip`, `SawTip`, los dos `SpinTip`): se cargan girando y se descargan con un directo.
  En un brazo discreto lo que tocan recibe el empujón por lo que giraba; en uno con músculos pegan como pega el brazo.
- **Cañón de energía** (`CannonTip`): **en lugar del antebrazo** (el usuario: «reemplazar antebrazo»), con su palanca y
  sus cuatro modos (ver abajo, «El cañón de energía»). Mientras tanto el brazo va adonde apunta, no a su postura.
- **Escudo** (`ShieldTip`, 18/11/2026, de la sesión de la cabina): la mano común siempre cerrada en el mango de un
  escudo físico rectangular. Levantado, sólo ese brazo va a la guardia (`wanted`), y no pega. Va al final de la lista de
  puntas, así los equipos guardados no se corren. Lo que frena y lo que gasta, en [[meca-jaula]].

Lo que una punta puede cambiar, en ganchos: lo que arma (`_build`), lo de cada paso (`step`), dónde se pide el puño
(`wanted`), qué pasa al conectar en un brazo discreto (`hit`), si el antebrazo lleva placa (`plates_forearm`) y lo que
muestra poseyéndola (`status`).

**La placa** (`MechArm.plated`) es la del acorazado de la armería (`ArmoryParts.plate`: tres caras de octógono del lado
de afuera), en el brazo y el antebrazo; el cañón, que reemplaza al antebrazo, la lleva sólo en el brazo.

**Qué lleva cada brazo de una meca** lo declara la meca: `Mech.loadout`, el izquierdo y el derecho, cada uno un
`ArmLoadout` (cómo se mueve, la punta, la placa). Vacío, los dos con el puño común sin placa (las mecas de siempre). Es
lo que elige y guarda **el panel de equipamiento** (`EquipmentPanel`, **F5** de las filas de mecas): el mismo
panel en todas, y **cada fila guarda el suyo** (`MechLoadout`, en `game/mech/arm_tips/saved/`, por el nombre de la
fila; los archivos son del usuario, como los de las perillas). Por brazo: cómo se mueve, qué lleva en la punta y si
lleva la placa; «Guardar» rearma las mecas. La meca sabe de qué fila es por `Mech.equipment` (lo pone su arquetipo);
sin fila (un test), lleva lo de su clase (`Mech.default_loadout`), y un `loadout` puesto a mano manda sobre
todo. Lo prueba `tests/equipment_check.tscn` (cambia el borrador, lo aplica sin escribir el archivo y mira la meca
rearmada). *El taladro, la sierra y el cañón gastan la energía de la meca (`ToolMech`, ver [[meca-jaula]]): en una
meca sin ella (una `Mech` suelta) se ven pero no andan, y sus teclas tampoco los manejan.* Para mirarlas todas: `tests/arm_tips_look.tscn` (una meca jaula
por punta, el brazo izquierdo discreto y el derecho con músculos).

*Hasta ese día el cañón, el taladro y el palo eran clases de brazo (`CannonArm`, `CageCannonArm`, `DrillArm`,
`PoleArm`): el cañón no podía tener músculos ni el palo ser discreto, había dos cañones distintos y el de la jaula
llevaba, además de la placa, la funda de la Meca de tres.* *Y la mano del puño común quedaba siempre del tamaño de la
meca grande: en la jaula, al 30 %, era enorme.*

## El taladro — `DrillTip` (y la sierra, `SawTip`)
Una mecha en vez de mano (nació en la Meca de tres, 15/11/2026). El usuario: «con el clic derecho… lo cargas y con el
otro clic… lo usas, porque no lo puedes usar de una porque tarda en agarrar velocidad… su propia barra, y mientras más
tiempo lo cargas… más energía gasta».
- **Cargar** (mantenido): la mecha toma velocidad (a fondo en 1,4 s) y gasta energía de a poco, más cuanto más gira.
  Suelto, se frena sola en 3 s.
- **Descargar**: el directo de siempre, al frente, sin apuntar. En un brazo discreto, lo que toca recibe el empujón del
  puño por un factor que va de 0,4 (casi quieta) a 2,6 (a fondo). Pide que gire por lo menos un 15 %. Después del
  golpe, gira un 30 % de lo que giraba.

## El cañón de energía — `CannonTip`
**En lugar del antebrazo** (el de la Meca de tres era una caja y un caño fino después de la mano, hasta el 16/11/2026).
El usuario: «un cañón que dispare, que tenga varios modos de disparo… simple, varios disparos chicos, uno que barra y
otro que sea un super disparo»; «que se controle con una palanca y que no sea tan controlable… que se mueva como el de
los músculos, pero sin la colisión».
- **La palanca** dice adónde apuntar (35° a cada lado, de 35° abajo a 30° arriba) y **queda donde la dejan**. **El
  brazo la sigue con un resorte con freno**: llega en medio segundo y se pasa un poco. Atraviesa todo (es discreto). El
  brazo va casi estirado, así el caño, que es el antebrazo, mira adonde apunta.
- **Cada tiro lo patea** para arriba y un poco de costado: el retroceso. La ráfaga sube sola si no se la corrige.
- **Los modos**:
  - **Simple**: un tiro mediano por apretada (6 % de energía; uno cada 0,3 s).
  - **Ráfaga**: mantenido, tiros chicos seguidos y un poco abiertos (1,2 % cada uno, 11 por segundo).
  - **Barrido**: mantenido, un rayo de 90 m que empuja lo que toca (32 % por segundo); se barre con la palanca.
  - **Súper**: mantenido, carga a fondo en 1,2 s (30 % por segundo; ya cargado, 8 %); al soltar, un tiro grande según
    la carga y una patada grande. *Que tire a la meca para atrás, después: a la cinemática todavía no la mueve un
    golpe.*
- **Los tiros** (`EnergyBolt`) van derecho y a lo primero que tocan le dan un impulso. Si tocan una pieza de una meca
  (un pie), el empujón va a la meca. **Sólo locales**: todavía no van por la red.
- **La costura con lo que lleva vida** (`EnergyBolt.lands`, para los tiros, el rayo y el taladro): además del empujón,
  si lo que recibe (o la meca de la pieza tocada) tiene `take_hit(strength, at, source)`, se lo dice: cuánto empujó,
  dónde y con qué («cañón», «rayo», «taladro»). Cuánta vida saca lo decide quien recibe (un jefe; lo pidió la sesión
  Jefes).

## Montado
Montado en algo que se mueve: la meca ([[meca-jaula]]) lleva dos. Montado, el músculo del hombro empuja
contra lo que lo sostiene (una piña sacude al torso) y pesa menos.

## Lo que falta
- La mano no agarra.
- Que la mano siga mejor lo pedido en la piña (hoy va atrás y llega con látigo): pedirle también velocidad.

## Los golpes por segmentos (22/11/2026; F3, pestaña Golpes)
- **Puño o palo, dos segmentos:** apretar paga 8. Soltar antes del 35 % de la carga pierde esa energía y no pega; desde ahí sale
  **liviano**. Al llenarse (1 s) paga 10 más y sale **pesado**; sin energía para pagarlo, se queda en liviano.
- **Cañón, tres segmentos de 0,8 s:** cada uno cuesta 12 y se paga al empezarlo. Soltar antes del primero no dispara. El primero
  necesita tener su energía; los siguientes pueden dejar la batería en negativo, y entonces viene el stun al disparar. El daño
  y el empuje son un tercio por segmento, y el largo salta de 9 a 11,5 y 14 m.
- Mientras se carga no se recarga la batería. La barrita de cada brazo se dibuja por segmentos (`MechChargeBar`).

## La piña al soltar (22/11/2026)
El tramo que pega va a 4 veces la velocidad de la piña común (`MechArm.RELEASE_SPEED`); antes iba a 2.
