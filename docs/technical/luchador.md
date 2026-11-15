# El Luchador de orugas

**Módulo Jefes, desde el 15/11/2026.** El jefe humanoide, de a un paso con el usuario: «la trayectoria del juego va a
ser más con pelear enemigos más humanoides (con brazos y cabeza)… con variaciones, como 4 brazos, piernas de huellas de
tanque»; de las maquetas eligió el Luchador («iría con la de luchador, pero en vez de piernas les haría las huellas de un
tanque… y los tubos de atrás son los perfectos para que tiren humo cuando está enojado»). La maqueta y lo acordado, en
[[maquetas-jefes]]; la vida, las barras y la arena, en [[pelea-jefes]].

Código en `game/bosses/brawler/`: `Brawler` (cómo se mueve y lo que se le pide), `BrawlerBody` (el dibujo, en piezas que
se mueven), `BrawlerSettings` y `BrawlerPanel` (el F1) y `BrawlerArchetype` (la parcela). Fila **Luchador de orugas**,
en Jefes. Se mira con `tests/brawler_look.tscn` (con ventana, unos 50 s).

## Paso 1 (15/11/2026): cómo se mueve, sin ataques
- **La forma**, la de la maqueta: ancho, el pecho enorme, la cabeza hundida entre los hombros con un visor, los brazos
  cuadrados en guardia y dos chimeneas atrás; abajo, **dos orugas** con sus ruedas y el chasis, y un aro donde gira la
  cintura. Unos 30 m de alto (la meca, 18).
- **Cinemático** (el usuario: «empezaría con un jefe puramente cinemático»): el controlador de personaje del motor con
  una caja de 24 × 30 × 24 m contra lo fijo; para las mecas, su cuerpo (las orugas y un cilindro arriba) va en la capa
  de lo fijo: es una pared para ellas.
- **Las orugas, con rampas** (`MoveRamp`): llega a 10 m/s en 1,7 s (arranca pesado); **soltando sigue un poco** (5 m);
  **frena** apretando para el otro lado en 0,7 s; para atrás, a la mitad. A/D giran las orugas, en el lugar o andando:
  45°/s (en 2 s, 90°).
- **La cintura gira aparte**, sobre el aro, hacia donde mira (70°/s): puede andar para un lado y mirarte.
- **La arena**: no sale del círculo (150 m); contra el borde se desliza y queda a 138 m del medio.
- **El horno** (el usuario: «una sola al medio, abajo… que se note que es como un horno… una puerta que se abra… hacia
  arriba»): un solo horno al medio del pecho, abajo, con barras y la boca que brilla; la puerta tiene la bisagra arriba
  y se abre hasta 110°. **Es el punto débil**: a 15 m del piso, a la altura del pecho de la meca. Mañana se abre en la
  carga antes de embestir (la ventana) y con ira.
- **La ira**: el color pasa a negro, el visor a rojo, el horno brilla más, **humo negro por las chimeneas** y anda y
  gira 1,35 veces más rápido.
- **Poseído** (la O): W/S las orugas, A/D girarlas, el mouse la cintura, **Q** el horno, **G** la ira. En la parcela,
  **H** el horno y **P** la ira. **F1**: las perillas (Orugas, Cintura, Horno, Ira, Arena).
- Enfrente, la meca simplificada, con su vida y las barras; **todavía no pelean**.

## Lo que sigue
Los poderes, de a uno (propuestos, sin confirmar): el golpe doble al piso (onda en línea), la embestida en orugas (con
la ventana del horno y estrellándose contra el borde), el agarre y revoleo, el gancho al cielo, arrancar el piso y
tirarlo, la guardia con contraataque y el trompo; con ira, combos más largos y el humo como zona que tapa la vista. Sin
ametralladora por ahora. Después, su cabeza (la computadora), como un jefe de Souls.
