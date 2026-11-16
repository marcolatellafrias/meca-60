# La pelea con los jefes: lo común

**Módulo Jefes, 15/11/2026.** Las piezas de la pelea que quedaron del jefe bola (borrado ese día: el usuario, «la
trayectoria del juego va a ser más con pelear enemigos más humanoides… borraría todo lo de la bola») y que va a usar el
que sigue, el Luchador de orugas ([[luchador]]), que ya las usa.

- **La vida** (`Health`, `game/bosses/health.gd`): cuánta tiene algo y cuánta le queda, colgada como hijo («Vida») del
  jefe o de la meca. **Todo por código**: la baja quien decide que algo pegó (la cabeza del jefe), no los choques (el
  usuario: «un sistema de vida que por ahora sea todo vía código… bien simple por ahora»). *Cambia lo que decía el
  diseño («no hay vida»).*
- **Las barras** (`FightBars`): la del jefe arriba, la de la meca abajo, de quien esté a menos de 300 m.
- **La arena** (`BossArena`): **un círculo conocido de antemano** del que el jefe no sale (el usuario: «un radio central
  en la que pueden moverse… no debería tener un sistema que lee objetos en el momento… de la forma más simple que se
  pueda»). Sin rayos: el jefe le pregunta al círculo. El borde lo frena y se desliza (`keep`); si algo lo sacó, vuelve
  (`hold`); embistiendo será la pared contra la que se estrella (`at_edge`), y rebota en él (`bounce`). Los edificios van
  afuera; el medio, despejado. 150 m de radio. Probado con el jefe bola: caminando contra el borde quedaba a 134 m del
  medio (el borde menos su cilindro de 16).

## Lo que se aprendió con el jefe bola
- **El choque según el motor** (ver [[cuerpo-por-piezas]]): una meca cinemática choca sólo con lo fijo, así que lo grande
  del jefe que tiene que pararla va también en esa capa (para ella es una pared; si se le mete encima, su motor la saca).
  Con las cuatro mecas, la bola las paraba a 17–21 m de su centro.
- **El golpe**: la vida baja por código; a la meca física además la empuja (`BalanceBody.hit`) y su péndulo decide si cae.
- **La cabeza que pelea, como un jefe de Souls**: cada ataque con aviso, golpe y recuperación; elige por distancia, con
  azar, sin repetir tres veces; entre ataques te rodea.
- **Cambiar de meca** en la parcela (la K): la nueva tiene que nacer cuando la vieja ya no está, y sin nada suelto encima;
  si no, el motor la despide a lo bruto.

## Los golpes, como en Souls (15/11/2026)
El usuario: «no colisionen entre sí los personajes… sí puede colisionar. Fijate cómo lo hacen los bosses de Dark
Souls… el boss le pega a la mecha y la mecha se hace hacia atrás… que sea algo cinemático… un indicador que muestre
cuando le pegan… le ponés unos colliders en los puños que cuando tocan al personaje haciendo una cierta habilidad le
hacen daño… cuándo lo empuja, cuándo lo tira… el estado de la nave que se cae y se levanta, que también tiene que ser
cinemático».

Cómo lo hacen los Souls, y cómo queda acá:
- **Los cuerpos se bloquean, no se empujan.** Cada uno tiene su cápsula: no se atraviesan, pero el jefe no te arrastra
  con el cuerpo. Acá: la meca choca con el cuerpo del jefe (lo fijo, como siempre), y **el jefe no avanza dentro de la
  meca** (`Brawler.block_at`/`block_radius`, lo pone su cabeza): se frena contra ella. *Antes, el jefe se le metía
  encima y el motor de la meca cinemática la sacaba para atrás de golpe.*
- **El daño lo hacen zonas de golpe, no el cuerpo.** Van pegadas a lo que pega (los puños, el frente embistiendo), se
  prenden sólo en los cuadros del golpe de cada ataque y pegan **una vez por ataque**. Acá, por ataque, en la cabeza.
- **Cada ataque dice qué te hace** (`HitReaction.Kind`): **aguantás** (no te movés), **te empuja** (te corrés parado),
  **te derriba** (salís para atrás, caés, quedás tirado y te levantás; **tirado no se te puede pegar** y no manejás).
- **Que se note**: el que recibe **se pone blanco** un momento, **chispas** donde pegó y **un sonido** (`BossSounds`,
  sintetizados por código). En los Souls además se frena el tiempo unos cuadros y tiembla la cámara: todavía no.
- **Todo cinemático, y de la meca**: moverla y caerse lo hace ella (módulo Meca, a pedido de este; aa5da23):
  `BalanceBody.shove(offset, time, hop)` la corre su motor sin manejarse (también el revoleo), y
  `BalanceBody.knock_down(away)` la tira de espaldas, tirada, y se levanta (DOWN, LIFT, RIGHT: la inclinación es de su
  caja, así sus brazos y sus piernas la siguen solos; tirada no se le pega, `untouchable()`). `HitReaction` sólo elige
  qué pedirle según el ataque y pone el destello, las chispas y el sonido. A la física le da un impulso y cae con su
  física. *Antes `HitReaction` la movía e inclinaba desde afuera, pieza por pieza, después de su paso: se peleaba con
  sus piernas y la IK de sus brazos (el torso se salía, los brazos quedaban en el aire; el usuario: «estás peleando
  contra un sistema de gravedad y IK… arreglalo de raíz… coordiná con otros»). Tirada, el cañón apunta al cielo: la
  postura de los brazos al caerse la decide el módulo Meca.* `tests/hit_reaction_look` (con ventana, unos 10 s):
  capturas de empujada, cayendo, tirada y levantándose, y a qué altura queda tirada.

| Ataque del Luchador | Zona de golpe | Qué te hace |
|---|---|---|
| La embestida | el frente de su caja, embistiendo | te derriba, 22 m para donde va |
| El golpe al piso, los puños | los dos puños, al caer | te derriba, 8 m |
| El golpe al piso, la onda | el lomo, si estás apoyada | te derriba, 8 m para donde va |
| La piedra | el círculo donde cae | te derriba, 10 m desde el medio |
| El trompo | la parte de afuera de los dos brazos, hasta el puño (barriendo entre paso y paso) | te empuja 16 m de costado, parada |
| El agarre | la mano | te agarra, te revolea y te tira; al caer, derribada |
| El lanzallamas (con ira) | el cono de cada bocanada, mientras quema | te empuja 12 m, parada |
| Tus piñas al jefe | (de la meca) | él no se mueve: se pone blanco, chispas y sonido |

**Todo para un dash** (15/11/2026): hubo un dash intocable, como la rodada de Souls, y se sacó (el usuario: «no se lee
realista en la meca, se siente tonto»). Ahora se esquiva por posición, con un dash por vez (hay una espera entre
dashes) y con el momentum de la meca: cada ataque se diseña para que su zona entre en un dash más lo que se camina en el
aviso, y apunta y se queda quieto antes de pegar. Ver [[luchador]], paso 8. `HitReaction.untouchable()`: tirada,
agarrada o volando.

**Los golpes de la meca de tres al jefe** (sus tiros, el rayo, el taladro): llegan por la costura del módulo Meca,
`EnergyBolt.lands(body, impulse, at, source)`, que le dice `take_hit(strength, at, source)` a lo que recibe. Como el
cuerpo del jefe es lo fijo del mundo y los tiros no miran esa capa, cada jefe lleva **`BossHurtbox`**: una caja que no
choca con nada (congelada, sin máscara) en la capa común, que lo sigue y le pasa `take_hit` a su cabeza. El Luchador
saca 4 de vida por cada 100.000 kg·m/s de empujón, con un tope de 12 por golpe en el cuerpo, y en el horno abierto 5
veces más. Medido (`tests/brawler_shots_check`, sin ventana, 20 s): un tiro simple 2,8; la ráfaga 13 en 2 s; el rayo 12
en 2 s; el taladro cargado, 12 (sin tope, 38). El taladro ya no se cuenta también como piña.
