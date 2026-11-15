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
  a 26 m/s (en 0,5 s), derecho, corrigiendo poco (6°/s), hasta 5 s; **si te alcanza** (estás adelante y, de
  costado, dentro de su ancho más el tuyo), te saca 25 de vida y a la meca
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

## Ajuste contra la meca cinemática (15/11/2026)
El usuario: «tunea las distancias de dashes y todo eso, y podemos probar por ahora como contrincante de la meca propia
kinemática». `tests/brawler_dodge_check` (sin ventana, unos 3 minutos) le tira embestidas desde 50, 80 y 110 m y prueba
cada manera de esquivar: quieta, caminando de costado (desde el aviso o desde que arranca) y el dash de costado cuando a su
frente le faltan 8 a 45 m (solo, seguido de caminar, o dos seguidos). Acepta `--homing=`, `--tiempo=`, `--aviso=` y
`--dash=` para probar otros números sin tocar las perillas.
- **Antes** (3 s, 12°/s): desde 110 m no llegaba nunca; caminar no esquivaba; el dash, sólo de casualidad.
- **El ancho**: el Luchador mide 24 m y la meca 8; para que le pase al lado hay que correrse unos 16 m. **Un dash de la
  meca (12 m) solo no alcanza nunca.**
- **Ahora** (5 s, 6°/s): quieta o caminando, te alcanza siempre; **dos dashes seguidos cuando le faltan 24 a 32 m (un
  segundo antes) esquivan** desde cualquier distancia; antes, corrige; después, no llegás.
- **El dash de la meca, a 18 m** (del módulo Meca; con el sí del usuario, commit aparte): **uno solo esquiva cuando le
  faltan 16 a 24 m** (medio segundo antes), desde cualquier distancia; antes corrige, después no llegás. Dash y después
  caminar, o dos dashes, esquivan desde que le faltan 16 a 45 m.
- `tests/brawler_charge_movie.tscn`: el video de la pelea (con `--write-movie`, de costado a los dos).

## Paso 3 (15/11/2026): las poses y el golpe doble al piso
El usuario: «estaría bueno que tenga alguna animación… cuando se preparan para embestir y cuando embiste… diría que sigas
con las otras habilidades».
- **Las poses** (`Brawler.Pose`; `BrawlerBody.pose`): el torso se inclina y los brazos giran enteros en el hombro, y
  puede temblar. Cada una llega en su tiempo. **Preparando la embestida**, agachado, los brazos atrás, temblando;
  **embistiendo**, inclinado y los puños adelante; **aturdido**, desplomado; **el golpe al piso**, los brazos arriba
  (echado atrás, temblando) y los puños al piso.
- **El golpe doble al piso** (`BrawlerBrain._slam`, `BrawlerWave`): **aviso** (1,3 s), levanta los brazos y en el piso
  aparece **una franja roja** por donde va a salir la onda (sigue a la cintura, que te mira); **golpe**, los puños al
  piso y sale **la onda**: un lomo de tierra de 14 m de ancho y 5 de alto que corre derecho a 45 m/s hasta 140 m. Si te
  pasa por debajo te saca 20 (a la meca física la levanta). Se queda 1,4 s. Sus perillas, en la pestaña «Golpe al
  piso» del F1.
- **Cuál ataque**: al terminar de rodear, uno de los que tengan tu distancia a tiro (la embestida entre 35 y 140 m, el
  golpe entre 25 y 120), al azar. **La L** de la parcela deja uno solo (todos, sólo la embestida, sólo el golpe).
- **Esquivarlo** (`brawler_dodge_check`, con la meca cinemática): quieta, te alcanza siempre; **caminando de costado,
  sólo de lejos** (80 m o más); **el dash, si lo hacés con anticipación** (cuando a la onda le faltan 15 m o más);
  **saltar, en su momento**: cuenta si vas más alto que el lomo cuando pasa, o sea, saltando cuando le faltan 15 a 25 m
  (antes ya estás bajando; después todavía no subiste).

## Paso 4 (15/11/2026): más rápido, y arrancar el piso y tirarlo
El usuario: «la embestida es lentísima, hacela mucho más rápida, y la piedra del suelo también un poco más rápida y
empezá con el 3er poder» (el tercero de la lista: arrancar el piso y tirarlo).
- **La embestida, de 26 a 55 m/s** (llega en 0,3 s; dura como mucho 3 s, cruza la arena igual). Esquivarla ahora es
  **un dash cuando le faltan 32 a 45 m** (0,6 a 0,8 s antes): más cerca ya no te corrés a tiempo. Quieta o caminando,
  te alcanza siempre. **La onda del golpe al piso, de 45 a 60 m/s.**
- **Arrancar el piso y tirarlo** (`BrawlerBrain._throw`, `BrawlerRock`; entre 35 y 130 m): **mete las manos** (1 s,
  agachado, temblando) y saca un pedazo de piso de 14 × 6 × 11 m que sale de a poco; queda **el pozo**. **Aviso**
  (1,1 s): la levanta sobre la cabeza y en el piso aparece **un círculo rojo que te sigue**. **Golpe**: la tira en arco
  (35 m de alto, 1,8 s de vuelo, de cualquier distancia) y el círculo se queda donde estabas. Si te cae encima (radio 9
  más tu medio ancho), te saca 30 y se rompe; si no le pegó a nadie, queda en el piso 8 s y se hunde.
  **Sin chocar con nada** (el usuario: «que no tenga colisión, porque hace que ella misma se choque contra ella»: el
  Luchador se trababa con sus propias piedras). Sus perillas, en la pestaña «Arrancar el piso» del F1.
- **Esquivarla** (`brawler_dodge_check --solo-piedra`): quieta, te cae encima; **caminando de costado** (desde el aviso
  o desde el tiro) **o con el dash, no**. Al filo: con 1,3 s de vuelo, caminando ya no llega y sólo la esquiva el dash.
- **La L** suma «sólo arrancar el piso». El video (`brawler_charge_movie`) arranca con 20 s de piedras.

## Paso 5 (15/11/2026): el trompo y el agarre y revoleo
El usuario: «hacé el trompo y el agarre y revoleo… obvio que el agarre se debería poder esquivar, es un skillshot».
- **Las poses** suman cuánto se abren los brazos para los costados (`BrawlerBody.pose`, `spread`), y **la cintura puede
  girar sola** (`Brawler.spin`, °/s), sin mirar a donde apunta.
- **El trompo** (`BrawlerBrain._spin`; hasta 65 m): **aviso** (1 s), abre los brazos y empieza a girar despacio;
  **golpe**, gira a 540°/s durante 3 s y viene hacia vos a 12 m/s, con su arranque corto (la meca camina a 8). Si los
  brazos te alcanzan (30 m desde su medio, más tu medio ancho), te saca 20 (a la física la empuja de costado). Después
  queda **mareado 2 s, con el horno abierto**: la ventana. Pestaña «Trompo» del F1.
- **El agarre y revoleo** (`BrawlerBrain._hook_act`, `BrawlerHook`; entre 25 y 80 m), **un skillshot**: **aviso** (1 s),
  los brazos atrás y **una franja roja angosta** (6 m) que sigue a la cintura; después **se queda quieta y titila
  0,6 s** (ya apuntó, y la cintura también queda quieta); **golpe**, la mano sale derecho con su cadena a 90 m/s hasta
  85 m. Si te toca, vuelve arrastrándote; con vos adelante, **te revolea** (la cintura gira a 400°/s, 1,2 s) y **te
  tira** 70 m en arco (25 m de alto, 1,3 s; dentro de la arena); al caer te saca 35. Si no, vuelve vacía. A la meca
  física no la lleva: la tira hacia él y le saca lo mismo. Pestaña «Agarre» del F1.
- **Esquivarlos** (`brawler_dodge_check --solo-trompo --solo-agarre`): el trompo, quieta te alcanza siempre; **desde
  45 m, caminando para atrás** te escapás; más cerca, sólo **con un dash para atrás en el aviso** y caminando. El
  agarre, quieta o caminando desde el aviso te agarra (la franja te sigue); **desde 55 m, salirte caminando cuando
  apuntó** alcanza; más cerca, **con el dash** (cuando apuntó o cuando sale la mano).
- **La L** suma «sólo el trompo» y «sólo el agarre». El video arranca con 16 s de agarres y 16 de trompos.

## Lo que sigue
Los poderes, de a uno (propuestos, sin confirmar): el gancho al cielo y la guardia con contraataque; con ira, combos más largos y el humo como zona que tapa la vista. Sin
ametralladora por ahora.
