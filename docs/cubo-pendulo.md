# El cubo péndulo

`game/pendulum_cube/` · fila **Cubo péndulo** · ver [[filas]]

**El modelo de equilibrio de la meca** (12/11/2026). No es el de los personajes: el personaje es una cápsula con campo
de fuerza y su inclinación son huesos; la meca tiene colisión 1:1 con su caja y su inclinación es la del cuerpo.

## La idea
**Un solo cuerpo físico, el torso (la caja), que siempre va adelante; los pies siempre lo siguen.**

- **Péndulo invertido**: un palo rígido va del centro del cubo al **punto de apoyo**, en el piso. La punta del palo está
  agarrada a ese punto; el cubo sólo gira alrededor de él. Inclinarse lo baja, solo.
- **Caminar empuja al torso**, en su centro, hacia la velocidad pedida, con inercia para arrancar y para frenar. Los
  pies no empujan nada.
- **El punto de apoyo sigue al torso**: quiere estar debajo e ir a su velocidad. **Frenar es instantáneo** (un pie se
  planta), pero para alcanzarlo reacciona con demora y acelera con tope. Los pies no tienen inercia propia: la inercia
  es del torso.

## Lo que sale de ahí
- **Piña**: le da velocidad al torso, la punta queda agarrada atrás y el cubo se inclina hacia donde va. Los pies salen
  a alcanzarlo; si no llegan antes de *se cae inclinado más de*, cae. **Arriba vuelca más que abajo.**
- **Pared**: frena al torso y los pies se plantan debajo. No hay nada que alcanzar: **no se cae, a ninguna velocidad**.
- **Arrancar**: se inclina un poco adelante (los pies van atrás) y se nivela al llegar a velocidad. Al frenar, nada.
- **Correr hacia una piña de frente** inclina menos que recibirla parado: primero tiene que frenarte.

## El resto
- **El giro en Y**: un motor hacia donde pide el mouse, con velocidad tope y dos topes de fuerza, como los pies:
  **girar él es débil** (del orden de caminar) y **frenar un giro que le dieron es fuerte**. Si algo lo traba, no gira;
  un golpe descentrado lo gira un poco y vuelve. *Con un solo tope fuerte, girar apoyado en una pared lo despedía: la
  pared devuelve el torque como un empujón, unas cinco veces lo que empuja caminar.*
- **La caja no roza** (fricción 0, parada): lo que la frena son los pies.
- **Las piernas son dibujo** (IK, `MechBody`): pisan por radio alrededor del apoyo, mirando como el torso; cada pie
  guarda hacia dónde miraba al pisar y **la pelvis**, una sola pieza, mira al promedio de los dos pies. Caído se pliegan;
  al enderezarse, se estiran.
- Pasado el ángulo, **o sin piso bajo su apoyo** (un borde, un pozo), cae, suelto del todo, y se recupera con las
  toberas del [[cubo]].
- **O** lo maneja: W/S hacia donde mira el torso, A/D de costado, el mouse gira.

## Las dos perillas
- **Los pies** (*cuánto aceleran*, *qué tan rápido reaccionan*): cuánto se inclina con un golpe y cuánto golpe lo tira.
  El tope de aceleración tiene que ser más que la aceleración de caminar, o al arrancar se cae de cara.
- **El freno del torso** (*freno al soltar*): cuánto retrocede.

Están atadas por la geometría: inclinarse es que el torso se fue de arriba de los pies.

## Lo medido (12/11/2026)
| Golpe (m/s que le cambiaría la velocidad suelto) | En el centro | Arriba |
|---|---|---|
| 5 | 4°, se corre 2 m | 7°, 3,4 m |
| 8 | 10°, 4,7 m | 16°, 7,8 m |
| 11 | 17°, 8,2 m | **cae** |
| 14 | **cae** | cae |

- Pared a 8, 14 y 20 m/s: 4° (lo que ya traía de caminar), no cae.
- Arrancar: 4° adelante; a velocidad, 0°; frena en unos 5,5 m.
- Girar 90°: 1,2 s. Un golpe descentrado de 6 m/s lo gira 12° y vuelve.
- Volcado, parado otra vez a los 4 s.

## Inclinación por el propio movimiento: las opciones
Hoy es la **B**. Pendiente probar la C y la D.
- **A. Nada**: sólo los golpes inclinan.
- **B. Lo que sale solo**: adelante al acelerar, se nivela; al frenar, nada.
- **C. Perilla por código**: el objetivo «derecho» se inclina según la aceleración, adelante y atrás.
- **D. Inclinada siempre que corre**: riesgo, llega a la pared con el canto de arriba.

## Lo que sigue
1. Golpes en las piernas (colisionador que sigue al IK; el golpe se pasa con una regla: más lenta, pies más lentos).
2. Un brazo con músculos (estilo PuppetMaster: cuerpos unidos que persiguen la pose de la IK o de una piña), en su fila.
3. El torso mismo como músculo del mismo sistema.

Perillas: `PendulumCubeSettings` (F1). Test: `tests/pendulum_check.tscn`.
