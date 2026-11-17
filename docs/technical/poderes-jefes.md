# Los poderes de los jefes

El sistema para armar y variar los ataques de los jefes (17/11/2026). El usuario: «un sistema robusto… más
modularizados distintos tipos de ataque… que yo después pueda hacer variaciones… tildo los poderes… cada poder le puedo
cambiar unas variantes… libertad sin tantos sliders».

## Qué es un poder
`BossPower` (game/bosses/powers/) es un ataque. Es un recurso que tiene dos partes:
- **Sus perillas**, en una pestaña del panel del jefe:
  - el tilde («lo usa»);
  - desde y hasta qué distancia lo usa;
  - si es sólo con ira;
  - **sus pocas variantes**: cuántas ondas, cuántas piedras, cuántas bocanadas, si rebota.
- **Su código**, por tiempos:
  - `start`, al elegirlo;
  - `act`, en cada paso mientras es el ataque de ahora, con el aviso, el golpe y la recuperación (`b.step`, `b.clock`,
    `b.next(n)`, `b.finish()`);
  - `tick`, siempre, porque lo que lanzó sigue en el mundo (las ondas, las piedras);
  - `drop`, si lo cortan.

Lo que **pide del cuerpo** (`needs`: "embestir", "brazos", "mano", "horno"). Si al jefe le falta, no lo usa, y la
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

## Lo que sigue (el plan acordado)
1. **Piezas que se combinan dentro de los poderes**:
   - un aviso opcional en el piso, aparte de la pose;
   - el golpe desde una parte del cuerpo que barre, desde una zona alrededor o desde algo que larga al mundo;
   - y eventos: «al pegar en el piso, larga una onda», sirve igual para un puño que para un misil.
   - Los proyectiles se comparten con la artillería de la meca propia, cinemáticos o físicos.
2. **La cabeza con fases y rutinas**: cómo se mueve entre ataques y qué la hace cambiar.
3. **El cuerpo modular**: piezas con enchufes y reglas de qué va con qué.
