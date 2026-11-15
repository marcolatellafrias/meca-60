# El Luchador de orugas

**Módulo Jefes, desde el 15/11/2026.** El jefe humanoide, de a un paso con el usuario: «la trayectoria del juego va a
ser más con pelear enemigos más humanoides (con brazos y cabeza)… con variaciones, como 4 brazos, piernas de huellas de
tanque»; de las maquetas eligió el Luchador («iría con la de luchador, pero en vez de piernas les haría las huellas de un
tanque… y los tubos de atrás son los perfectos para que tiren humo cuando está enojado»). La maqueta y lo acordado, en
[[maquetas-jefes]]; la vida, las barras y la arena, en [[pelea-jefes]].

Código en `game/bosses/brawler/`: `Brawler` (cómo se mueve y lo que se le pide), `BrawlerBody` (el dibujo, en piezas que
se mueven), `BrawlerBrain` (la cabeza: lo maneja la computadora), `BrawlerSettings` y `BrawlerPanel` (el F1) y `BrawlerArchetype` (la parcela). Fila **Luchador de orugas**,
en Jefes. Se mira con `tests/brawler_look.tscn` (cómo se mueve, con ventana, unos 50 s) y
`tests/brawler_fight_look.tscn` (la pelea, unos 70 s).

## Paso 1 (15/11/2026): cómo se mueve, sin ataques
- **La forma**, la de la maqueta: ancho, el pecho enorme, la cabeza hundida entre los hombros con un visor, los brazos
  cuadrados en guardia y dos chimeneas atrás; abajo, **dos orugas** con sus ruedas y el chasis, y un aro donde gira la
  cintura. Unos 28 m de alto (la meca, 18). *Bajado 2 m y con las orugas más cortas (18 m) el mismo día, para que la
  meca llegue al horno con los puños.*
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
  y se abre hasta 110°. **Es el punto débil**: a 13 m del piso, adonde llegan los puños de la meca.
- **La ira**: el color pasa a negro, el visor a rojo, el horno brilla más, **humo negro por las chimeneas** y anda y
  gira 1,35 veces más rápido.
- **Poseído** (la O): W/S las orugas, A/D girarlas, el mouse la cintura, **Q** el horno, **G** la ira. En la parcela,
  **H** el horno y **P** la ira. **F1**: las perillas (Orugas, Cintura, Horno, Ira, Arena).


## Paso 2 (15/11/2026): la cabeza y la embestida
El usuario, al probarlo: «poseo la meca simplificada… pero no pasa nada, no me hace agro»; acordado: que te rodee y te
embista, con la ventana del horno. `BrawlerBrain`, como un jefe de Souls (aviso, golpe, recuperación):
- **Rodea**: la cintura te mira siempre; las orugas se acercan si estás a más de 80 m, se alejan si estás a menos de 45 y,
  en el medio, van en diagonal (un tanque no camina de costado). Cada 2 a 4 s, si estás entre 35 y 140 m, embiste.
- **La embestida**: **aviso** (1,4 s): frena, se da vuelta hacia vos y **abre el horno** (la ventana); **golpe**: arranca
  a 26 m/s (en 0,5 s), derecho, corrigiendo poco (12°/s), hasta 3 s; **si te alcanza**, te saca 25 de vida y a la meca
  física la empuja (18 m/s). Después frena, se recupera 1,5 s y cierra el horno.
- **Si llega al borde de la arena, se estrella**: para en seco y queda **aturdido 2,5 s con el horno abierto** (otra
  ventana).
- **Las piñas de la meca** cuentan con el brazo estirado: en el horno abierto le sacan 30; en el cuerpo, 6.
- **En la parcela**: **J** si piensa, **K** el tipo de meca (física, mixta, cinemática con brazos y cabina, que es la de
  arranque, o simplificada, que no puede pegar), **H** el horno, **P** la ira. Las perillas, en el F1 (pestañas
  Embestida y Golpes).
- **Su cuerpo para las mecas**: las orugas y una caja para el torso que gira con la cintura (así se le llega de frente
  al pecho).
- Medido (`brawler_fight_look`, la meca cinemática quieta): en 35 s embistió 2 veces y la alcanzó las 2 (le dejó 50);
  contra el borde se estrelló a 137,5 m del medio; dos piñas al horno abierto le sacaron 60.
- **Conocido, sin daño**: las pruebas con una meca con cabina hacen caer a Godot al cerrar (sólo al cerrar; sin cabina,
  no). El generalista: pasa en el cierre, también en `possess_character` y `possess_check`; no hace falta resolverlo,
  salvo que se caiga antes de terminar la prueba.

## Lo que sigue
Los poderes, de a uno (propuestos, sin confirmar): el golpe doble al piso (onda en línea), el agarre y revoleo, el gancho al cielo, arrancar el piso y
tirarlo, la guardia con contraataque y el trompo; con ira, combos más largos y el humo como zona que tapa la vista. Sin
ametralladora por ahora.
