# La meca cinemática

**Rearmada** (13/11/2026) con lo que enseñó el [[laboratorio-cinematico]]. Es la meca de siempre ([[meca]]): los mismos
brazos, la cabina, las sillas, las piernas, la escalera y las animaciones. **Lo único que cambia es cómo se mueve.** Fila
**Meca cinemática**; test `mech_kinematic_look`. El usuario: «lo único que cambia es que se mueve de forma cinemática».

**La simplificada** es esta misma meca, con el mismo código y el mismo F1, armada **sin brazos y sin cabina**
(`arms_kind` NONE, `has_cabin` false): una caja lisa con una franja amarilla al frente. Es la del Laboratorio cinemático.

## Cómo
- **Un interruptor del cuerpo**: `BalanceBody.kinematic`, que se pone antes de armarla. Con él la caja queda congelada y
  la mueve **`KinematicMover`**, un `CharacterBody3D` del motor (`move_and_slide`).
- **Contra lo fijo del mundo, un cilindro** que envuelve la caja y el vidrio de adelante, y mira **sólo la capa de lo
  fijo** (`PhysicsLayers.FIXED`). Un piso o una pared que no esté marcado como fijo, la meca lo atraviesa: el sandbox lo
  marca; un test que arma su propio piso tiene que marcarlo (`PhysicsLayers.mark_fixed`).
- **Contra lo suelto**, el motor sin reglas extra: la caja empuja, y **los pies con choque** (`StompFeet`), que siguen a
  los pies de las piernas, patean de costado. **Lo que queda debajo de un pie que baja, o de la caja al agacharse, se
  achata**: suena, larga polvo y desaparece. Los personajes todavía no.
- **Movimiento discreto, en metros y segundos** (perillas en `KinematicSettings`, F1 `KinematicPanel`, con pestañas):
  una velocidad y el tiempo para llegar a ella; giro con tope; salto sólo para arriba; vuelo con su barra; dash (Shift
  con dirección) en el piso y en el aire con su barra; agacharse. **La meca física conserva lo suyo** (fuerzas, correr,
  el dash sólo en el aire): cada una lo suyo físico, la forma (F2) es compartida.
- **La altura**: la de las piernas del F2, igual que la física.
- **Los golpes no le hacen nada todavía** (`push_impulse` y `push_force` no la mueven): con movimiento discreto falta
  decidir qué le hace un golpe. Tampoco se cae.
- Para ponerla en otro lugar sin barrer el camino: `put`. Para manejarla desde un test o un cerebro: `scripted`.

## Lo de adentro: como si la meca estuviera quieta (vale para las dos mecas)
El usuario: «una vez que están adentro los personajes y los paquetes, es como si estuvieran quietas las cosas… la regla
es siempre la misma». En `MotionFrame`: la inercia que se siente es 0; lo suelto que entra lo adopta el marco y va
clavado mientras está quieto; las sillas giran con la meca.

## Medido (13/11/2026, `mech_kinematic_look`)
Camina, salta, dash de costado, se corre, dos giros de 90°, corre y frena:
- **Dos cubos sueltos adentro** se corren contra la meca 0,00 m. Las sillas giran 90° con ella.
- **La pila alta de adelante** sale pateada hasta 27 m/s; una caja se achata.

## Lo que falta
- **Qué le hace un golpe**, y si se cae.
- **Las patadas** a lo mediano son fuertes (ver el laboratorio).
- **Choque entre mecas**: dos cinemáticas se atraviesan.
- **Los brazos físicos** (`MuscleArm`) leen el giro de la caja, que acá es 0: la fila usa los discretos.
- La red, sin probar.
