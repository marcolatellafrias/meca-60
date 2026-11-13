# La meca cinemática (maqueta)

**Maqueta** (13/11/2026). `game/kinematic_mech/` · fila **Meca cinemática** · test `kinematic_mech_look`. La otra
variante, la de hoy, en [[meca]] y [[pendulo]].

## Qué es
La tercera alternativa, ni física ni mixta. El usuario: «la totalmente cinemática… así puedo hacer dashes, otras cosas
con más libertad, sin hacer fuerzas enormes que puedan buguear el mapa». **Cinemática no es sin física: la física la
escribe ella.** Jolt no la mueve. Cada paso, `KinematicMech` calcula dónde va y se pone ahí: es un `AnimatableBody3D`, así
el motor sabe su velocidad, lleva lo que tiene encima y empuja lo suelto.

- **El mismo péndulo que la meca física, escrito a mano.** El torso tiene su velocidad y el apoyo lo sigue con las mismas
  reglas (frenar es instantáneo; alcanzarlo tiene tope). La inclinación es lo que el torso se adelantó a su apoyo, sobre
  el largo del palo. Las perillas son las mismas (`BodySettings`, el F1).
- **Un golpe** es un cambio de velocidad del torso (`push`). Pasado `fall_tilt` **se cae**: es una caída escrita, que
  vuelca alrededor del apoyo hasta quedar acostada, y después se levanta.
- **Lo fijo la frena.** Todo movimiento se prueba antes (también subir y bajar); contra algo fijo, se desliza y pierde la
  velocidad que iba contra eso. **Lo suelto no la frena: lo empuja.**
- **El giro** tiene tope de velocidad y de aceleración. **Si algo fijo lo traba, no gira**: la caja girada se prueba
  antes.
- **Un borde**: si el piso baja más de 2 m de un paso al otro, queda en el aire y cae.
- **Los de adentro** van en su `MotionFrame`, como en la meca de siempre: el marco les suma lo que cambia la velocidad de
  la caja en su punto. **Esto ya estaba resuelto, sea la meca física o no.**

## Lo medido (13/11/2026, `kinematic_mech_look`)
La rutina de la K: camina, salto cargado, dash de costado contra una pared, se corre, media vuelta, corre y frena.
- **Los llevados como la gente** (no sienten la inercia, como el jugador): se despegan del piso 0,11 m como mucho y se
  mueven contra la caja a 0,6 m/s como mucho. No se mueven de su lugar.
- **El suelto que siente la inercia entera** sale volando por arriba: la caja está abierta arriba y el dash la frena
  contra la pared a 18 m/s. Es lo esperable; cuánto sienten las cajas lo dice la perilla de inercia del marco.
- **La pared** la frena: no se mete nada.
- **La pila de afuera** sale despedida hasta 13,9 m/s: es el caveat de empujar con masa infinita. Hay que ponerle una
  regla.
- **Un golpe fuerte** la inclina, se cae (escrito) y se levanta. Los de adentro siguen en su lugar.

## Los errores que aparecieron
- **La sombra del marco copiaba la caja entera.** Los de adentro quedaban metidos en una caja maciza y salían despedidos
  a 127 m/s. Ahora copia sólo `interior`.
- **Saltando por arriba de una pared baja, al bajar se metía en ella**, porque sólo se probaba el movimiento de costado.
- **Girando pegada a una pared**, las esquinas se le metían adentro; al salir, saltaba 2 m en un paso y los de adentro
  salían despedidos.
- **Pasando el borde de arriba de una pared, bajaba 16 m de golpe**, porque el rayo del piso era largo.

## Lo que falta
- Una regla para lo suelto que empuja (un tope, o no chocar y empujar con un impulso calculado).
- Choque entre mecas: dos cuerpos cinemáticos se atraviesan.
- Que las piñas de la meca física (`PoseArm`) le peguen: hoy hacen `apply_impulse` y a un cuerpo cinemático no le pasa
  nada.
- El casco es una caja abierta arriba. Las piernas son un dibujo simple de dos pies que se acomodan, no `BodyLegs`.
- La red, sin probar.
