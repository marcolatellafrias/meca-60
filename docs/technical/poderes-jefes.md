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

Lo que **pide del cuerpo** (`needs`: "embestir", "brazos", "mano", "horno", "suelo", "volar"). Si al jefe le falta, no lo usa, y la
pestaña lo dice («le falta: …»). Cada jefe pelea con una **copia** de sus poderes: lo que guarda mientras pelea es de
esa copia. Al guardar el panel, las perillas nuevas pasan a las copias.

| Poder | Pide | Variantes |
|---|---|---|
| `ChargePower`, la embestida | embestir | con ira, rebota en el borde |
| `SlamPower`, el golpe al piso | brazos | cuántas ondas (y con ira), abiertas cuánto |
| `ThrowPower`, arrancar el piso | brazos | cuántas piedras (y con ira): las de más, adonde vas |
| `SpinPower`, el trompo | brazos | cuánto corrige hacia vos (0, derecho) |
| `HookPower`, el agarre | mano | el ancho de la franja, cuánto se queda quieta |
| `FlamePower`, el lanzallamas | horno | cuántas bocanadas; de entrada, sólo con ira |

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
Una sola perilla para todos los jefes: `BossSettings.scale`, en el F2 de la fila, que se cambia en vivo. Cada jefe
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

## Lo que sigue (el plan acordado)
1. **Piezas que se combinan dentro de los poderes**:
   - un aviso opcional en el piso, aparte de la pose;
   - el golpe desde una parte del cuerpo que barre, desde una zona alrededor o desde algo que larga al mundo;
   - y eventos: «al pegar en el piso, larga una onda», sirve igual para un puño que para un misil.
   - Los proyectiles se comparten con la artillería de la meca propia, cinemáticos o físicos.
2. **La cabeza con fases y rutinas**: cómo se mueve entre ataques y qué la hace cambiar.
3. **El cuerpo modular**: piezas con enchufes y reglas de qué va con qué.
