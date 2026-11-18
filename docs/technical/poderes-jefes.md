# Los poderes de los jefes

El sistema para armar y variar los ataques de los jefes (17/11/2026). El usuario: «un sistema robusto… más
modularizados distintos tipos de ataque… que yo después pueda hacer variaciones… tildo los poderes… cada poder le puedo
cambiar unas variantes… libertad sin tantos sliders».

## Qué es un poder
`BossPower` (game/bosses/powers/) es un ataque. Es un recurso que tiene dos partes:
- **Sus perillas**, en una pestaña del panel del jefe:
  - en qué modos lo usa (tranquilo y cada modo del jefe);
  - desde y hasta qué distancia lo usa;
  - **sus pocas variantes**: cuántas ondas, cuántas piedras, cuántas bocanadas, si rebota.
- **Su código**, por tiempos:
  - `start`, al elegirlo;
  - `act`, en cada paso mientras es el ataque de ahora, con el aviso, el golpe y la recuperación (`b.step`, `b.clock`,
    `b.next(n)`, `b.finish()`);
  - `tick`, siempre, porque lo que lanzó sigue en el mundo (las ondas, las piedras);
  - `drop`, si lo cortan.

**De dónde sale y con qué pega es libre** (el usuario: «no está el concepto de que existe un horno… yo decido desde
qué punto sale algo… así como ahora es un horno, también podría ser un cañón, un brazo de boxeo que le sale del pecho»).
El poder no sabe qué hay en el cuerpo. El cuerpo ofrece, por nombre libre, **sus puntos** (de dónde puede salir algo),
**sus zonas de golpe**, **sus poses** y **sus aspectos**; y en la pestaña de cada poder se elige de una lista: «sale
de», «pega con», «pose del aviso», «pose del golpe», y el tilde «deja a la vista el punto débil» (en el Luchador, abrir
el horno es eso). Son las perillas que terminan en `_point`, `_zone`, `_pose` (y `look` en los modos); el panel las
vuelve listas con `BossPower.choice_spec`. Lo único que un poder **pide** (`needs`) es físico: «suelo»; si el jefe
vuela, no lo usa. Cada jefe pelea con una **copia** de sus poderes: lo que guarda mientras pelea es de esa copia. Al
guardar el panel, las perillas nuevas pasan a las copias.

| Poder | Pide | Usa del cuerpo (de entrada) | Variantes |
|---|---|---|---|
| `ChargePower`, la embestida | suelo | pega con «cuerpo»; expone el punto débil | en modo fuerte, rebota en el borde |
| `SlamPower`, el golpe al piso | suelo | pega con «puños» | cuántas ondas (y en modo fuerte), abiertas cuánto |
| `ThrowPower`, arrancar el piso | suelo | sale de «entre los puños» | cuántas piedras (y en modo fuerte) |
| `SpinPower`, el trompo | suelo | pega con «puntas»; expone al marearse | cuánto corrige hacia vos |
| `HookPower`, el agarre | suelo | — | el ancho de la franja, cuánto se queda quieta |
| `FlamePower`, el lanzallamas | nada | sale de «pecho»; expone | cuántas bocanadas |
| `BombPower`, el bombardeo | nada | sale de «arriba» | cuántas, cada cuánto, físicas, con anillo |

## Lo común: la cabeza
`BrawlerBrain` es lo que comparten los poderes:
- **Rodear** y **elegir**: al azar, entre los tildados que tienen la distancia a tiro (los de ira, sólo con ira).
- **Encadenar con ira.**
- **El blanco**: dónde está, su ancho y su alto.
- **Los golpes**: `strike`, por HitReaction; y si un punto lo toca, `touches_target`.
- **Manejar**: `face`, `drive`, `error_to`.
- **Lo que le pegan a él.**

La **L** de la parcela deja un solo poder (aunque no tenga ira), para probarlo.

## La escala
Una sola perilla para todos los jefes: `BossSettings.scale`, en el F7 de las filas de jefes, que se cambia en vivo. Cada jefe
está dibujado en sus medidas de maqueta y va a esa escala. **Lo que sale de su cuerpo escala con él**: su caja, el
frente de la embestida, los puños y los brazos del trompo, la altura de la mano del agarre. **Las zonas tienen su
propio tamaño**, en las perillas de cada poder: el ancho de la onda, el radio de la piedra, el cono del lanzallamas
(el usuario: «las que dependen del tamaño… se escalarían automáticamente… las que son en área… las debería poder
cambiar yo independientemente»).

## Las zonas de golpe, por pieza del cuerpo
El usuario: «que cada componente pueda tener hitboxes y un poder activa una cierta cantidad de hitboxes durante un
cierto periodo». Cada cuerpo dice sus zonas de golpe por nombre (`Brawler.hit_shapes(part)`: cápsulas en el mundo, que
escalan con él): "cuerpo", "puños", "brazos", "puntas". Un poder las prende en cada paso que dura su golpe con
`b.hit_with(piezas, cuánto más grandes, daño, qué, reacción, hacia dónde, cuánto empuja)`: barre desde el paso
anterior y pega una vez por ataque. La embestida prende "cuerpo"; el trompo, "puntas"; el golpe al piso, "puños".

## Los modos (la ira es uno más)
El usuario: «el concepto de ira es muy estructurado… podría haber varios tipos de ciclos… un boss que se queda volando
y tirando bombas». `BossMode` es un tramo de la pelea con otras reglas; un jefe tiene una lista (una pestaña por modo
en su panel) y fuera de todos está tranquilo.
- **Cuándo entra**: cada tanto tiempo tranquilo (un ciclo) o cuando su vida baja de una parte (una fase, una vez).
  **Cuánto dura** (0, hasta el final). Entra y sale mientras rodea, nunca en medio de un ataque.
- **Qué cambia**: cuánto más rápido anda, si encadena ataques, si los poderes usan sus **variantes fuertes**, **a qué
  altura vuela**, a qué distancia rodea, y si se ve con ira.
- **Cada poder dice en qué modos se usa** (tranquilo, modo 1, modo 2).
- El Luchador tiene dos: **la ira** (como antes) y **el vuelo** (apagado de entrada: sube a 30 m con sus propulsores y
  pelea con lo que no pide suelo). La **P** de la parcela los cambia a mano.

## Cómo se mueve un jefe
Lo pone su cabeza, según el modo (`Brawler`): con **las orugas** (como un auto: gira y avanza); **para cualquier lado**
(`omni`, para un jefe de patas, o siempre que vuela: va hacia `go`); **volando** a una altura (`fly_height`); y **un
salto** en arco hasta un punto (`jump(a dónde, en cuánto, cuánto sube)`, con `landed_now` al caer), que cualquier poder
puede pedir. En el aire le falta el «suelo»: los poderes que lo piden no se usan (`lacks_now`).
`tests/boss_modes_check` (sin ventana, 30 s): cada modo, qué poderes deja, la altura, la vuelta al piso y un salto.

## Las zonas en el piso
`BossZone` es la pieza común de todo ataque «geométrico»: **círculo, franja, cono y anillo** (que puede crecer solo:
una onda redonda que se abre). Es la cuenta de si un punto está adentro (`covers`) y, si se quiere, la marca que avisa.
**La marca es opcional**: `BossSettings.floor_marks` (en el F7) la apaga para todos, y entonces todo se lee por las
poses y los sonidos, como en Souls; `marked` la apaga para una. No hace daño: el poder que la usa decide cuándo pega.
La usan la onda y el agarre (franja), la piedra y las bombas (círculo), el lanzallamas (cono) y el anillo de las bombas.

## Lo que se lanza al mundo
`BossShot` es una bomba, un misil o un cascote. Vuela y **avisa al caer** (`landed`, con dónde): lo que pasa ahí lo
decide el poder (pegar en una zona, largar un anillo, otra cosa). Dos maneras de volar:
- **cinemática** (`launch`): un arco conocido; se puede marcar dónde cae desde que sale;
- **física** (`toss`): un cuerpo de verdad que rebota en lo fijo y «cae» al cabo de tantos rebotes o de su mecha; no
  se sabe dónde termina, hay que mirarla.

`BombPower`, **el bombardeo**, las usa: larga bombas por arriba, una tras otra, alrededor tuyo. Variantes: cuántas y
cada cuánto, la zona, la dispersión, **si son físicas** (rebotan, sin marca; estallan también si te tocan) y **si al
caer largan un anillo** que se abre y hay que saltar. De entrada, sólo volando.
*Los proyectiles viejos de la meca propia (`Missile`, `AreaStrike`, `ProjectileField`: por la red y empujando con
física) son otro sistema; cuando se defina la artillería de la meca, se juntan.*

## Las tres maneras de pegar (y de esquivar)
Son tres juegos distintos, y un poder elige una o las mezcla:
1. **Una pieza del cuerpo que barre** (`hit_with`): se lee por la animación, como en Souls.
2. **Una zona** (`BossZone`): geométrica, con o sin marca.
3. **Algo lanzado** (`BossShot`): cinemático o físico, y lo que hace al caer.

## Reglas para quien siga
- Un ataque nuevo es **un `BossPower` nuevo** en `game/bosses/powers/`, no código en la cabeza de un jefe.
- Para pegar, usar **una de las tres maneras de arriba**; no escribir otra cuenta de «si lo toca» ni otra marca.
- Lo que el golpe le hace al que recibe va **siempre por `HitReaction`** (`b.strike`).
- Un tramo de la pelea con otras reglas es **un `BossMode`**, no un caso especial.
- **Nada figurativo en las reglas**: un poder no pide «un horno» ni «una mano»; elige un punto, una zona o una pose de
  las que el cuerpo ofrece por nombre. Lo único que se pide es físico (suelo).
- Las variantes son **pocas perillas del poder**; lo que depende del tamaño del jefe sale de su cuerpo y escala solo.
- Cada pieza que haga falta y no esté (otra forma de zona, otra manera de volar) **se agrega a la pieza común**.

## El cuerpo modular
El usuario: «un sistema modular de mecas… 2 o 3 modelos de piernas, de brazos, de torso y de cabeza… pensar en las mecas
no como estéticas, sino como superficies que soportan o no ciertos attachments… yo después puedo agarrar módulos y
modelarlos a mano». En `game/bosses/parts/`:
- **`BossParts`, el catálogo**: cada pieza es un dato (qué es, qué ofrece, qué pide) y un dibujo de arcilla provisorio
  (`draw_*`); cambiar el dibujo por un modelo no toca el dato.
  - Piernas: orugas, dos patas, cuatro patas, flotante. Dicen cómo se mueven (orugas, patas,
    vuelo), la altura de la cadera y lo que dan (suelo, embestir, saltar, volar).
  - Torsos: ancho, angosto, de cuatro brazos. Dicen cuántos hombros tienen y de qué tamaño, y lo que dan
    (horno, núcleo).
  - Brazos: puño, pinza, cañón, escudo. Dicen qué tamaño de hombro piden y lo que dan (brazos, mano,
    cañón, escudo).
  - Cabezas: visor, antena, sin cabeza.
- **`BossRecipe`, la receta**: qué piezas lleva un jefe. Dice **si encaja** (`problems`: sólo lo que es de lugar, un
  brazo entra en un hombro de su tamaño o más grande; la regla de peso se sacó, el usuario la vio muy figurativa) y
  **qué ofrece** a los poderes: sus puntos y sus zonas de golpe, por nombre (`points`, `zones`), y lo físico (`gives`).
  Una pieza no dice qué es («tiene un horno»): dice qué puntos y qué zonas tiene.
- **`BossFrame`, el armazón**: monta la receta (las piernas, el torso en la cadera, un brazo en cada hombro, la
  cabeza), a la escala de todos los jefes, con sus zonas de golpe por nombre.
- **La fila «Taller de jefes»** (`BossWorkshopArchetype`): adelante, el que se arma (J piernas, K torso, L brazos, H
  los del segundo par, P cabeza), con su cartel: qué lleva, si encaja y por qué no, lo que le dan sus piezas y qué
  poderes podría usar; atrás, cinco ejemplos. `tests/boss_parts_look` (con ventana, 10 s): capturas de tres recetas.
- *Todavía es sólo el cuerpo, quieto: el Luchador sigue siendo un cuerpo hecho a mano. Falta que un armazón pelee
  (la cabeza común) y que las piernas pongan cómo se mueve.*

## Los paneles
- **F1 de la parcela de cada jefe**: ese jefe (su cuerpo, sus modos, sus poderes).
- **F7 en todas las filas de jefes**: «Todos los jefes» (`BossSettingsPanel`): la escala y las marcas en el piso. El
  sandbox no tiene panel de supercategoría: es la misma tecla en cada fila.

## Lo que sigue
1. **Que un armazón pelee**: la cabeza común a todos los jefes (hoy es `BrawlerBrain`, atada al Luchador) y un jefe
   genérico que se arma de una receta, con las piernas poniendo cómo se mueve. El Luchador pasa a ser una receta.
2. **Poses por pieza**: hoy las poses son del Luchador; los brazos del armazón tienen que poder levantarse y abrirse.
3. **Rutinas de rodeo por modo** (ir por zonas, mantener un lado) y más poderes.
4. **Ajustar los poderes a la meca jaula** (a escala humana): hoy casi todo le pega.
5. Juntar los proyectiles con la artillería de la meca propia.
