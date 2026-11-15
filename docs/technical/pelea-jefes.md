# La pelea con los jefes: lo común

**Módulo Jefes, 15/11/2026.** Las piezas de la pelea que quedaron del jefe bola (borrado ese día: el usuario, «la
trayectoria del juego va a ser más con pelear enemigos más humanoides… borraría todo lo de la bola») y que va a usar el
que sigue, el Luchador de orugas ([[maquetas-jefes]]). Hoy no las usa ninguna parcela.

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
