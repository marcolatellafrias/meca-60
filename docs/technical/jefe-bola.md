# El jefe bola

`game/bosses/` · fila **Jefe bola** (supercategoría Jefes) · test `ball_boss_look` · ver [[laboratorio-cinematico]],
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
- **Se mueve como el cubo cinemático**: con el controlador de personaje del motor (`CharacterBody3D`). Contra lo fijo
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
  Tentáculos. **Guardar** las deja en `game/bosses/ball_boss_settings.tres` (`KnobsFile`), que se carga al arrancar; el
  archivo es del usuario y no va al repositorio.

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
  y gira sobre el eje de la rendija: a 0° mira adelante, a 90° al cielo, a 180° atrás, y **da la vuelta entera**. Todavía
  no dispara; `muzzle()` dice desde dónde y hacia dónde saldría el tiro.
- **Lo que se le pide**: `aim_pitch`, como `aim_yaw` para girar. El cañón va hacia ahí por el camino más corto, con tope
  de velocidad (60°/s; la pestaña Cañón del F1).
- **Poseída, el mouse arriba y abajo mueve el cañón**; de costado, el mouse gira la bola entera.
- Medido: pedido a 0°, 45°, 90°, 180° y −45°, llega a cada uno.

### Lo que falta o queda abierto
- Los tentáculos atraviesan lo fijo: el cilindro sólo cubre la bola, y un tentáculo puede cruzar una pared baja para
  apoyar del otro lado.
- Los pies no tienen choque: no patean ni achatan lo suelto, como hacen los del cubo.
- Ideas del usuario para más adelante:
  - disparar adelante o al cielo, para que caiga una lluvia de misiles;
  - hacerse bola y rodar más rápido, con las patas retraídas;
  - las hélices como melee;
  - disparos cargados, rayos;
  - dos cañoncitos al costado.
