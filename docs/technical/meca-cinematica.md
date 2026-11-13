# La meca cinemática

**En pausa** (13/11/2026): primero se define cómo trata lo suelto en el [[laboratorio-cinematico]]. **Primera versión**
(13/11/2026). Es la meca de siempre ([[meca]]): los mismos brazos, la cabina, las sillas, las
piernas, la escalera, las toberas y las animaciones. **Lo único que cambia es cómo se mueve**: a mano, en vez de Jolt.
Fila **Meca cinemática**; test `mech_kinematic_look`. El usuario: «lo único que cambia es que se mueve de forma
cinemática»; «así puedo hacer dashes, otras cosas con más libertad, sin hacer fuerzas enormes que puedan buguear el
mapa».

## Cómo
- **Un interruptor del cuerpo**: `BalanceBody.kinematic`, que se pone antes de armarla (`MechArchetype(arms, true)`). Con
  él, la caja queda congelada (cinemática) y la mueve `BodyKinematic`.
- **Una sola puerta para empujarla y leer su velocidad**: `push_force`, `push_impulse`, `velocity()`, y para cualquier
  cuerpo `BalanceBody.hit`. Caminar, saltar, el dash, el propulsor, las piñas, los misiles y las zonas pasan por ahí, así
  que no saben si la meca es física o cinemática.
- **El mismo péndulo, escrito a mano**: el apoyo sigue al torso con las mismas reglas y perillas (F1). La inclinación es
  lo que el torso se adelantó al apoyo, sobre el largo del palo.
- **Caerse es escrito**: vuelca alrededor del apoyo hasta quedar acostada, espera y se levanta. La caída física rodaba
  contra el piso; acá no hay piso que la haga rodar.
- **Lo fijo la frena**: cada movimiento se prueba antes, también subir y bajar, y contra algo fijo se desliza.
- **El giro tiene tope de aceleración**, y si algo fijo lo traba, no gira.
- **Un borde**: si el piso baja más de 2 m de un paso al otro, queda en el aire y cae.

## Lo de adentro: como si la meca estuviera quieta (vale para las dos mecas)
El usuario: «una vez que están adentro los personajes y los paquetes, es como si estuvieran quietas las cosas… no me
interesa tener físicas complejas adentro de la meca… la regla es siempre la misma». En `MotionFrame`:
- **La inercia que se siente es 0** (`inertia_felt`).
- **Lo suelto que entra lo adopta el marco** (un paquete, un cubo; los personajes entran solos). Va **pegado, como
  hijo**: mientras está quieto queda clavado en su lugar de la meca, y su gravedad apunta hacia el piso de la meca, así
  que inclinada o caída no resbala. Si algo lo empuja, se suelta y se mueve; al quedarse quieto, se vuelve a clavar.
- **Las sillas giran con la meca** (medido: la meca giró 90° y las sillas también).

## Medido (13/11/2026, `mech_kinematic_look`)
La rutina fue: camina, salto cargado, dash de costado contra una pared, se corre, dos giros de 90°, corre y frena, y un
golpe fuerte.
- **Los maniquíes sentados y dos cubos sueltos** se corren contra la meca 0,01 m como mucho, contando la caída.
- **La pared** la frena: no se mete nada.
- **Un golpe fuerte** la tira (69°) y se levanta.
- **La meca física**, después del cambio, da lo mismo que antes: el salto sube 10,5 m y los dashes la corren 15,7, 34,8
  y 21,2 m.

Lo que enseñó la primera maqueta, que se borró: la sombra del marco tiene que copiar sólo lo de adentro; hay que probar
también el movimiento vertical, el giro y los bordes. Y llevar lo suelto sumándole velocidades no alcanza: se corría
0,6 m en la rutina y 5 m al caerse. Por eso ahora va clavado.

## Lo que falta
- **Lo suelto de afuera**: una pila alta sale despedida hasta 27 m/s, porque la caja empuja con masa infinita. Hace falta
  una regla.
- **Choque entre mecas**: dos cinemáticas se atraviesan.
- **La bola de prueba** (la J) rebota sin moverla, porque es un choque de Jolt y no pasa por su puerta.
- **Los brazos físicos** (`MuscleArm`) leen el giro de la caja, que acá es 0. Por eso la fila usa los brazos discretos.
- **Los personajes** que caminan adentro siguen con la gravedad del mundo: si la meca se cae, se caen. Pegados van sólo
  los paquetes.
- La red, sin probar.
