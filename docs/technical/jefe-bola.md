# El jefe bola

`game/bosses/` · fila **Jefe bola** (supercategoría Jefes) · tests `ball_boss_look` y `ball_brain_look` · ver [[laboratorio-cinematico]],
[[contratos]]

El primer jefe, pensado por el usuario (13/11/2026): «una bola con una rendija en el medio que le da toda la vuelta y
ahí tiene un cañón que puede girar toda la circunferencia, y que tenga cuatro patas… como tentáculos con hélices al
final». Se arma **de a poco, un paso por vez** («quiero ir haciendo cosas de a poco en este personaje»).

## Paso 1 (13/11/2026): la bola y las patas
Para ver la forma, cómo camina, cómo choca y cómo se mueve. **Sin cañón, sin dash y sin vuelo.** La maneja quien la
posee (la **O**). La computadora todavía no.

- **La bola** (`BallBoss`): mide 30 m y su centro va a 20 m del piso, así que el techo queda a 35 m. Es **casi el
  doble de la meca**, que mide 18 m («por lo menos el doble… después podemos cambiar las escalas»), y va **cerca del
  piso**: la panza, a 5 m.
- **La rendija va de arriba a abajo**: da toda la vuelta de adelante, por arriba, hacia atrás. Separa dos medias
  esferas, la izquierda y la derecha, y mide 4 m de ancho y se hunde 0,6 m, con el fondo oscuro. El cañón va a subir y bajar por ella:
  disparar adelante o al cielo. **Para apuntar de costado, la bola gira con las patas** (el usuario, 13/11/2026: «la
  rendija es en la otra dirección, si quiere rotar en y, va a usar las piernas»). El cañón va metido en ella (paso 2).
- **Se mueve como el cubo cinemático** (hoy, la meca simplificada): con el controlador de personaje del motor (`CharacterBody3D`). Contra lo fijo
  del mundo choca con un cilindro de 16 m de radio, que va del piso a lo alto de la bola. Contra lo suelto y los
  personajes choca la bola misma, un `AnimatableBody3D` que la sigue. El movimiento es discreto:
  - caminar: una velocidad y un tiempo para llegar a ella;
  - girar: con tope de velocidad y de aceleración;
  - saltar: sólo para arriba;
  - **agacharse sólo baja la bola**, de 20 m a 15,5 m (la panza casi toca el piso); los tentáculos se doblan solos.
- **Los tentáculos** (`Tentacle`) tienen **su propio IK**, aparte del de la meca (el usuario: «no me gusta el sistema IK
  que tiene la meca… mantenerlo separado y modularizado»).
  - Cada tentáculo es **una curva de largo fijo**: sale de la bola hacia afuera y un poco para arriba, y entra al pie
    desde arriba.
  - Lo único que se busca, con una búsqueda binaria, es cuánto se abre la curva para que mida lo que mide el tentáculo
    (24 m).
  - No hay cadena que iterar ni rodillas que salten de lado. Si la bola baja, sobra largo y el tentáculo se arquea
    para arriba; si no llega, queda recto.
- **Son gruesos y cortos** (de 3,2 m de radio en la bola a 2,2 m en el pie; el usuario: «mucho más chunky y cortas»).
- **Los pies son cuatro paletas triangulares en cruz**, de 7 m de largo, apoyadas en el piso. Son el `rotor` del tentáculo: el mismo
  elemento va a girar como hélice («con un solo elemento cubrimos las dos cosas»).
- **Los pasos** (`BallLegs`):
  - Cada pie tiene su lugar en diagonal, a 24 m del centro, un poco adelantado si camina.
  - El piso se busca con un rayo a lo fijo del mundo, así que sobre un edificio pisa el techo.
  - Cuando un pie queda a más de 6 m de su lugar, sale **con el de su diagonal**, en arco.
  - En el aire, los pies cuelgan; al caer, apoyan donde estén.
- **F1**: las perillas (`BallBossPanel`), con una pestaña por grupo: Moverse, Girar, Saltar, Agacharse, Cañón y
  Tentáculos. Como todos los paneles de perillas (`KnobsPanel`), se mueve un borrador: **Guardar** lo aplica y lo
  deja en `game/bosses/ball_boss_settings.tres`, que se carga al arrancar; el archivo es del usuario y no va al
  repositorio.

### Lo medido (`ball_boss_look`)
| Prueba | Resultado |
|---|---|
| Caminar | 6 m/s; en 5 s, 5 pasos de a dos |
| Agacharse | el centro baja de 20 a 15,5 m |
| Saltar | sube 8 m |
| Girar 90° en el lugar | 4 pasos |
| Contra la pared | el centro queda a 16,00 m (el radio del cilindro) |
| Al lado del edificio de 12 m | dos pies en el techo (a 12,4 m) y dos en el piso |

## Paso 2 (13/11/2026): el cañón por la rendija
- **El cañón** (`BallCannon`), como de tanque: un carro metido en la rendija, un caño amarillo de 12 m y, en la punta,
  una boca más gruesa y larga (5,5 m) con el hueco oscuro bien a la vista (el usuario: «así parece más un cañón de
  tanque»; «más larga la parte ensanchada… y volvamos a los anchos antes de la exageración»). Cuelga del centro de la bola
  y gira sobre el eje de la rendija: a 0° mira adelante, a 90° al cielo, a 180° atrás, y **da la vuelta entera**.
  `muzzle()` dice desde dónde y hacia dónde sale el tiro.
- **Lo que se le pide**: `aim_pitch`, como `aim_yaw` para girar. El cañón va hacia ahí por el camino más corto, con tope
  de velocidad (60°/s; la pestaña Cañón del F1).
- **Poseída, el mouse arriba y abajo mueve el cañón**; de costado, el mouse gira la bola entera.
- Medido: pedido a 0°, 45°, 90°, 180° y −45°, llega a cada uno.

## Paso 3 (13/11/2026): los tiros
Van por `ProjectileField` (por red, como los de la arena de esquivar), que es un hijo fijo de la parcela.
- **El simple** (clic izquierdo; `fire`): derecho adonde apunta el cañón, hasta lo primero que encuentra (400 m como
  mucho), a 120 m/s. Es un proyectil nuevo de `Missile`, `Kind.SHELL`: va en línea recta, con su marca y su explosión.
- **Los del cielo** (clic derecho; `barrage`): **una sucesión, no una lluvia**, porque es un solo cañón (el usuario:
  «tendría más sentido que no sea una lluvia sino una sucesión de misiles del cielo»). El cañón sube solo a 90°, tira
  cinco morteros, uno cada 0,35 s, y vuelve adonde apuntaba. Caen en fila hacia adelante, el primero a 50 m y cada uno
  12 m más lejos, con su marca en el piso. Cuando la maneje la computadora, van a caer sobre el jugador y adonde va.
- Entre tiro y tiro, 0,8 s. Todo en la pestaña **Disparos** del F1.
- Medido: el simple, apuntando a −20°, pega en el edificio a 35 m; los del cielo caen a 50, 62, 74, 86 y 98 m.
- Todavía no hace daño: empujan lo suelto, como los misiles de la arena.

## Paso 4 (13/11/2026): hecha bola
`BallRoll`. El usuario: las patas «se meten adentro», «puede doblar», Shift lo cambia, y «que haga daño al tocar».
- **Shift** (`curl`) **se hace bola y otra vez se abre**. En 0,8 s, los tentáculos se acortan hacia adentro de la bola
  y la bola baja hasta apoyarse; contra lo fijo, el cilindro pasa a ser del ancho de la bola. Al abrirse, los pies
  salen hacia su lugar en el piso.
- **Rueda sólo hecha bola del todo**:
  - W acelera hasta 20 m/s, ganando 10 m/s por segundo;
  - S frena, y va un poco para atrás;
  - A/D y el mouse doblan, con su propio tope de giro (70°/s);
  - la bola se ve girar según lo que avanza.
  - **El cañón se mete**: corre hacia adentro por su eje hasta quedar dentro de la rendija, y no dispara (el usuario:
    «el cañón se tiene que meter también»).
- **Pega al tocar** (sin vida: todo es equilibrio): lo suelto que toca rodando a más de 4 m/s sale despedido, con un
  cambio de velocidad de hasta 16 m/s según lo rápido que iba. Es `BalanceBody.hit`, así que a una meca su péndulo
  decide si cae. A cada cosa le pega una vez por toque.
- En la parcela hay **una fila de ocho cajas** de 3 m y 400 kg para pegarles; la **R** las vuelve a poner.
- Todo en la pestaña **Bola** del F1.
- Medido: plegada, el centro queda a 15 m (el radio); rueda hasta 20 m/s; contra las cajas pegó 10 veces y la más
  rápida salió a 30 m/s; doblando 2,5 s con D giró 145°; abierta, vuelve a 20 m.

## Paso 5 (13/11/2026): el barrido con las paletas
`BallLegs`. El usuario: «barrido», con la Q.
- **Q** (`sweep`): los cuatro pies se levantan, las paletas giran como hélices y dan una vuelta entera alrededor de la
  bola, a 30 m del centro y a 4 m del piso, en 1,4 s. Después bajan donde quedaron y los pasos los acomodan. Mientras
  barre, no camina.
- **Pega**: lo suelto que toca una paleta (a 8 m de su centro) sale despedido de costado, hacia donde va la paleta, con
  un cambio de velocidad de 18 m/s (`BalanceBody.hit`). A cada cosa, una vez por barrido.
- Todo en la pestaña **Barrido** del F1; con vueltas negativas, gira para el otro lado.
- Medido: al lado de la fila de cajas, pegó a las 8.

## Paso 6 (13/11/2026): lo maneja la computadora
`BallBrain`. El usuario: «poné las variantes vos, pensá en bosses del Dark Souls». El blanco es **la meca simplificada**
(`Mech` sin brazos ni cabina, cinemática), que está enfrente en la parcela: con la **O** se la posee y se pelea. La **P** apaga y prende la cabeza. Mientras alguien
posee al jefe, la cabeza no hace nada.
- **Cada ataque tiene tres tiempos**: el aviso (se ve venir), el golpe y la recuperación (el hueco para castigarlo).
  Arriba del jefe, un cartel dice qué hace y en qué tiempo; el aviso, en naranja.
- **Elige por distancia**, con algo de azar, y **no repite** el mismo ataque tres veces seguidas:

| Distancia | Ataques (peso) |
|---|---|
| Cerca (menos de 40 m) | barrido (3), carga (1) |
| En el medio (40 a 85 m) | ráfaga (2), carga (2), los del cielo (1) |
| Lejos (más de 85 m) | los del cielo (2), ráfaga (1) |

- **Los ataques**:

| Ataque | Aviso | Golpe | Recuperación |
|---|---|---|---|
| Ráfaga | apunta el cañón, 0,8 s | tres tiros derechos, uno cada 0,9 s | 1,2 s |
| Los del cielo | el cañón sube | cinco: uno donde estás y los otros adonde vas | 1,6 s |
| Barrido | la bola se hunde, 0,7 s | el barrido entero | 1,3 s |
| Carga | se pliega | rueda hacia vos hasta 3,5 s, corrigiendo poco | frena, se abre y queda 1,8 s |

  La carga termina antes si se pasa del blanco o si choca con lo fijo.
- **Entre ataques te rodea**, de 0,8 a 1,8 s: de lejos se acerca, de cerca se aleja un poco y en el medio camina de
  costado mirándote. **Gira lento**: ponerse atrás es la forma de esquivarlo, salvo del barrido, que da la vuelta entera.
- **Sin vida**: lo que agarra al blanco se cuenta («te pegó») y se ve en el cartel; a lo suelto lo empuja como siempre.
  La meca simplificada no se empuja, por eso sólo se cuenta.
  - Un tiro cuenta si explota en su columna.
  - El barrido, si una paleta pasa a menos de 8 m de su borde.
  - La carga, si la bola lo toca rodando; una vez por carga.
- Medido (`ball_brain_look`, 60 s; los primeros 20 s la meca quieta, después dando vueltas de costado y con dash):
  con la meca quieta, la ráfaga le pega los tres tiros y los del cielo los cinco. Moviéndose, varía de una corrida a
  otra: en una eligió la ráfaga 3 veces, la carga 2, el barrido 1 y los del cielo 3, y le pegó 10 veces en total.

### Lo que falta o queda abierto
- Los tentáculos atraviesan lo fijo: el cilindro sólo cubre la bola, y un tentáculo puede cruzar una pared baja para
  apoyar del otro lado.
- Los pies no tienen choque: no patean ni achatan lo suelto, como hacen los del cubo.
- Contra lo fijo sólo choca el cilindro, así que puede salirse de la parcela rodando.
- El jefe y la meca se atraviesan (los dos miran sólo lo fijo).
- La meca no tiene cómo pegarle al jefe todavía.
- Elige mucho la carga: falta ajustar los pesos jugándolo.
- Ideas del usuario para más adelante:
  - disparos cargados, rayos;
  - dos cañoncitos al costado.
