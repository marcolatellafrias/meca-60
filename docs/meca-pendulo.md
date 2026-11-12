# La meca péndulo

`game/pendulum_mech/` · fila **Meca péndulo** · ver [[filas]]

El [[cubo-pendulo]] camino a ser la meca: mismo equilibrio (el torso es un péndulo sobre su apoyo, los pies lo siguen),
con cabina de tres pisos, brazos, y correr, agacharse, saltar y volar. El cubo péndulo queda como estaba, de referencia.

## Por dentro y por fuera
Se arma con **paredes de verdad**, no con una caja pintada: **tres pisos** con la proporción del cubo (2,67 m cada uno),
cada uno con el hueco del frente con su **vidrio** y sus parantes (se ve para adentro y para afuera), **el hueco de la
puerta atrás** (sin escalera todavía) y un asiento con su consola. La primera persona de [[poseer]] es la del asiento
del medio.

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
`MechExterior`. Se eligió entre cinco maquetas la del **zigzag fino** (las otras —marineras, caracol, una pasarela por
piso— se borraron). Todo de barras y rejilla finas, para que se lea como algo puesto encima del cubo.

- **La pasarela en U de planta baja**: atrás, de costado a costado, y por los dos costados hasta antes de donde cuelgan
  los brazos; 1,1 m de ancho, con baranda.
- Atrás, **un balcón por puerta** de los pisos de arriba y, por fuera, **un tramo liviano** de piso a piso, yendo y
  viniendo.
- **Dos tableros** para reparar, uno en cada costado (dibujo, por ahora).

**Se camina**: es parte del marco. Cada piso, cada tramo (una rampa) y cada baranda tienen su forma de choque; por las
puertas se pasa de los balcones a los pisos. Medido: parado en la pasarela, el balcón y el tramo, los pies quedan donde
van; caminando desde el balcón se entra al piso por la puerta.

Desde el suelo se sube por el ascensor de la pelvis (abajo). Idea para después: piernas más estiradas y la meca
lo bastante lenta como para escalar las piernas o los brazos.

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
- **G**, poseída, lo baja y lo sube; el **F2** tiene un botón para lo mismo. Tarda unos 2 s.

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

En el aire va derecha y sin apoyo; cuando la punta del palo vuelve a tocar el piso, aterriza. Caminar por un borde la
deja en el aire (no se cae tirada, como el cubo).

El cartel de poseer muestra la carga del salto y lo que le queda al propulsor.

## Lo medido (12/11/2026)
- Agachada: el centro baja 3,7 m.
- Salto: un toque sube 4,7 m; cargado entero, 10 m. Aterriza derecha, sin caerse.
- Propulsor: con el salto entero y todo el combustible llega a unos 42 m.
- Camina a 8 m/s y corre a 14,4; al soltar Shift tarda unos 3 s en volver a 8.

Perillas: `PendulumMechSettings` (F1). Test para mirar: `tests/pendulum_mech_look.tscn` (unos 25 s, sin el sandbox).
