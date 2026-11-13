# La meca péndulo

`game/mech/` · filas **Meca discreta** y **Meca física** · ver [[filas]] y [[estructura]]

## Dos caminos (13/11/2026)
La meca está **bifurcada**: todo es común —el péndulo, los pisos, el afuera, el ascensor, las piernas— menos los brazos
(`Mech.arms_kind`). Ver [[brazo]].
- **Meca discreta** (el camino más probable): peleas contra jefes NPC, zonas que esquivar, proyectiles. Brazos de pose
  (`PoseArm`): atraviesan y, al conectar, empujan con un impulso.
- **Meca física**: arena entre dos grupos. Brazos con músculos (`MuscleArm`): chocan, se traban, ceden.
En los dos la caja es un cuerpo físico 1:1 (se camina por adentro y por afuera): sólo se la mueve con fuerzas e
impulsos. Los límites de cada camino moldean lo que cada uno puede hacer. Cada fila tiene adelante una meca de
práctica, sin brazos, para pegarle.

Su equilibrio es [[pendulo]] (el torso es un péndulo sobre su apoyo, los pies lo siguen); encima, la cabina de tres
pisos, los brazos, y correr, agacharse, saltar y volar. Es una clase con sus piezas aparte: ver [[estructura]].

## Por dentro y por fuera
Se arma con **paredes de verdad**, no con una caja pintada: **tres pisos**, cada uno con el frente de **vidrio** y
sus parantes (se ve para adentro y para afuera) y **la puerta atrás**. Desde el 13/11/2026 **todas las medidas salen de
una grilla de celdas** (ver [[cabina]]): la planta baja es de servicio, con el ascensor, y los dos pisos de arriba tienen
dos asientos cada uno. La primera persona de [[poseer]] es la del asiento de la izquierda del piso del medio.

## Adentro se camina
Como en la meca de pelea, es un **marco** (`MotionFrame`, de character-parametric):
- Las losas y las paredes tienen forma de choque, pero **no chocan con el mundo**: el piso, las bolas y las paredes de
  afuera los sigue recibiendo la caja 1:1 de siempre.
- El que entra al volumen (el cubo) pasa a ir **en el marco**: la meca lo lleva con ella, y adentro choca sólo con la
  copia de esas losas y paredes (la «sombra» del marco). La caja de afuera deja de chocar con él.
- Todavía no hay escalera: **U** lo sube al piso del medio, o el ente entra volando.

Medido (12/11/2026), con el jugador con cuerpo parado en el piso del medio: la meca se corre 35 m y él se mueve 4 cm en
la cabina; en un salto no se mueve; cuando la meca se cae, él se cae adentro y queda adentro.

## Los brazos
**Físicos**: dos [[brazo|brazos con músculos]] colgados de sus hombros, casi en el medio del costado (se probaron en
el último tercio, hacia atrás: más natural, pero alcanzaban 2,6 m menos hacia adelante). Persiguen su postura con fuerza tope: van atrás cuando la meca gira o se frena, ceden si les pegan, y una piña
sacude al torso. Pesan menos que el brazo del banco (0,4), para que una piña no la dé vuelta.

- **Dos posturas**, con la **F**: **normal** (los brazos a los costados, las manos abiertas) y **cubriéndose** (los
  puños cerrados adelante de la cabina). Caída, se recogen contra los hombros.
- **Las piñas**, por brazo (izquierdo / derecho): **clic izquierdo / derecho** el directo, **Q / E** el gancho,
  **Z / C** el uppercut, **1 / 3** desde arriba.

Medido (12/11/2026): las ocho piñas inclinan el torso menos de 1° y lo giran entre 2° y 4°, sin caerse; girando 90° los
brazos quedan hasta 0,2 m atrás de su lugar.

## El afuera
`MechExterior`. Todo de barras y rejilla finas, para que se lea como algo puesto encima del cubo.

- **La pasarela en U de planta baja**: atrás, de costado a costado, y por los dos costados hasta antes de donde cuelgan
  los brazos; 1,1 m de ancho. Dos tableros para reparar, uno en cada costado.
- **La escalera de atrás**: dos tramos paralelos, uno arriba del otro, que suben para el mismo lado por fuera, y **un
  balcón por piso**, los dos iguales, de punta a punta de la escalera. Del final de un tramo al arranque del otro se
  vuelve caminando por el balcón. Elegida entre ocho maquetas (las otras se borraron).
- **Se arma de superficies pisables** (rectángulos en planta con su altura en cada punta), y de ahí salen dos reglas:
  **la altura libre** sobre cada lugar pisable se mide (2,7 m; hacen falta 2,1), y **las barandas van donde hay
  caída**. *El primer zigzag tenía los dos tramos en el mismo carril: en el quiebre quedaban 1,1 m.*
- Se camina (cada piso, tramo y baranda tiene su forma de choque) y es parte del marco de la meca.

Por las puertas se pasa de los balcones a los pisos. Desde el suelo se sube por el ascensor de la pelvis (abajo). Idea
para después: piernas más estiradas y la meca lo bastante lenta como para escalar las piernas o los brazos.

## El ascensor de la pelvis
`PelvisLift`. Por donde se sube desde el suelo. Se eligió entre cuatro maquetas la de **cuatro parantes y un aro**, con
el ascensor casi del radio de la pelvis, para que se lean como una sola forma (las otras se borraron).

- **La pelvis es redonda**: un tambor hueco de pared fina, con las caderas a los costados. Gira con los pies y, redonda,
  siempre coincide con el cubo.
- **La losa de abajo del cubo tiene un recorte redondo** del mismo hueco, y alrededor, adentro del piso de abajo, **una
  baranda con el paso abierto hacia la puerta de atrás**.
- **El ascensor**: un piso redondo que llena el hueco, cuatro parantes y un aro. Los parantes son tan altos como el
  viaje: bajado, sus puntas siguen dentro de la pelvis (nada se estira); subido, el piso queda al ras del piso de abajo
  y los parantes son su jaula.
- Bajado, su piso queda a **0,7 m del suelo con la meca agachada** (un salto) y a 4,4 m parada.
- **G**, poseída, lo baja y lo sube; la **L** del panel chico hace lo mismo. Tarda unos 2 s.

**Se viaja en él**: su piso es parte del marco. Medido: el jugador parado en su piso baja y sube con él, sin caerse.

Falta probar subirse desde el suelo saltando, con la meca agachada.

## El piso, para la meca, es lo fijo
El rayo con que la meca (y los cubos) buscan el piso **saltea todo lo que se mueve**: una persona, una bola, un brazo.
*Con alguien parado en el ascensor, justo debajo del centro, el rayo de apoyo le pegaba a esa persona, la tomaba por
piso y la meca salía disparada (12/11/2026).* Es la segunda vez que ese rayo falla (la primera, «no hay piso» leído como
«piso muy abajo»).

## Lo que hace (poseída)
Lo vertical sale del **largo del palo** del péndulo, como en los personajes sale de su resorte de altura.

| Tecla | Qué hace |
|---|---|
| **Shift** (yendo adelante) | **Corre**: hasta 1,8 veces la caminata. Lo de arriba de la caminata es una banda que se gana y se pierde a la mitad de la aceleración (como el sprint de character-parametric) |
| **Ctrl** | **Se agacha**: el palo se acorta, el cuerpo baja y las piernas se doblan solas; camina a la mitad |
| **Espacio** (mantener y soltar) | **Salta**: mantener carga (el cuerpo baja), soltar salta, del 30 % a todo su salto según lo cargado. Se carga altura, no fuerza |
| **Espacio en el aire** | **Propulsor**: las toberas de abajo la empujan para arriba mientras le quede; se recarga en el piso |
| **Shift en el aire** | **Dash** (13/11/2026): un impulso de costado hacia donde apretás (sin dirección, adelante), con las toberas del otro lado; uno por salto, gasta un tercio del propulsor. **Sólo en el aire** (el usuario: «un dash con el sistema de piernas actual se vería raro»): al aterrizar, los pies frenan |

**El salto no flota** (13/11/2026; el usuario: «se siente como muy lento… no se siente snappy»): en el aire pesa 2,4
veces más, y bajando 1,3 veces más todavía (con el propulsor prendido, lo de siempre); la altura es la misma y se carga
en 0,45 s. En el aire va derecha y sin apoyo; cuando la punta del palo vuelve a tocar el piso, aterriza. Caminar por un borde la
deja en el aire (no se cae tirada, como el cubo).

El cartel de poseer muestra la carga del salto y lo que le queda al propulsor.

## Lo medido (12/11/2026)
- Agachada: el centro baja 3,7 m.
- Salto: un toque sube 4,7 m; cargado entero, 10 m. Aterriza derecha, sin caerse. *Desde el 13/11/2026 (el salto que no
  flota): un toque, 5,4 m en 1,3 s de aire; cargado, 10,5 m en 1,9 s (antes, unos 2,9 s).*
- Dash (13/11/2026): de costado en lo alto la corre 16 m hasta aterrizar; adelante corriendo, 35 m; atrás, 21 m.
  Aterriza sin inclinarse más de 1°. Test: `tests/mech_jump_look.tscn` (unos 30 s).
- Propulsor: con el salto entero y todo el combustible llega a unos 42 m.
- Camina a 8 m/s y corre a 14,4; al soltar Shift tarda unos 3 s en volver a 8.

Perillas: `BodySettings` (F1). Test para mirar: `tests/mech_look.tscn` (unos 25 s, sin el sandbox).
