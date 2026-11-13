# El laboratorio cinemático

**Experimento** (13/11/2026). `game/kinematic_lab/`. Fila **Laboratorio cinemático**; test `kinematic_lab_look`.
**La meca cinemática está en pausa** ([[meca-cinematica]]) hasta que este experimento diga cómo tiene que tratar lo
suelto. El usuario: «un cubo alargado que se mueva con caja en el piso, y así yo pruebo los distintos approaches de
interacción de cinemático con físico… vamos por partes. Primero definimos cómo actúa el exterior… después vemos cómo
hacemos que funcione con paquetes y con el giro».

## Qué hay
- **El cubo** (`KinematicPillar`): una caja de 6 × 12 × 6 m sobre dos pies (piernas de 6 m), poseíble con la O.
- **Lo mueve el controlador de personaje del motor** (`CharacterBody3D`, `move_and_slide`): se le da una velocidad, y él
  frena y se desliza contra paredes y esquinas, sabe si está en el piso y se sale solo si queda metido en algo. El
  usuario: «un sistema simple, barebones, sólido y que use las cosas del motor, y no reglas inventadas».
- **Con qué choca cada cosa:**
  - **Contra lo fijo del mundo** (edificios, paredes, el piso), **un cilindro** de 4,6 m de radio, más grande que el
    cubo, del piso al techo. Es la forma del `CharacterBody3D`, y mira **sólo la capa de lo fijo**
    (`PhysicsLayers.FIXED`, la 17). A él no lo ve nadie: no es un campo de fuerza para lo suelto ni para la
    tripulación. En la parcela hay un edificio y una pared larga para probarlo.
  - **Contra lo suelto, lo que se ve, por el motor y sin reglas extra**: la caja de arriba (un `AnimatableBody3D` que lo
    sigue) empuja lo alto, y **los pies** (`PillarFeet`), que tienen choque de verdad, **patean** de costado.
  - **Lo que queda debajo de algo suyo que baja se achata** (un pie, o la caja al agacharse o al caer): suena, larga polvo
    y desaparece. Es una regla del juego, no un parche de la física. **Los personajes todavía no se achatan**: falta ver
    cómo muere uno.
  - **Entre los pies queda libre.**
- **El movimiento es discreto, en metros y segundos** (el usuario: «pasar más a como funciona un character normal en un
  juego… movimiento más discreto y menos físico», para probar jefes; puede que más adelante vuelva algo de física
  encima):
  - **Moverse:** una velocidad y el tiempo para llegar a ella (0: al instante). Sin correr. **En el aire no se mueve de
    costado.** Tres configuraciones de un toque arriba del F1: Instantánea, Casi instantánea y Pesada.
  - **Girar:** con el mouse, con tope de velocidad y de aceleración.
  - **Saltar (espacio):** sólo para arriba. Sube tantos metros en tanto tiempo; la gravedad sale de esos dos números.
  - **Volar (espacio otra vez, en el aire):** sube a una velocidad fija mientras quede su barra, que se llena apoyado.
  - **Dash (Shift, con una dirección):** tantos metros en tanto tiempo, en línea recta, en el piso y en el aire.
    Mientras dura no lo afectan ni las teclas ni la gravedad. **Sin dirección no pasa nada.** Su barra se llena sola.
  - **Agacharse (Ctrl):** las piernas se acortan de a poco.
  - **Las toberas** (`PillarNozzles`), de placeholder: cuatro abajo al volar y cuatro a los costados en el dash.
  - Las dos barras se ven en el cartel de poseer. El F1 tiene pestañas: Moverse, Girar, Saltar y volar, Dash,
    Agacharse y Pies.
- **La K elige las cajas, una configuración por vez:**
  1. Chicas y livianas sueltas (60 cm, 30 kg).
  2. Una pila alta de medianas (1,6 m, 300 kg).
  3. Grandes y pesadas, como autos (2 × 1,6 × 4,2 m, 1500 kg).
  4. Una pared de medianas.
- **La N**: una lluvia de seis cajas de la configuración de ahora, encima del cubo.

## Lo medido (13/11/2026, `kinematic_lab_look` y `kinematic_lab_moves_look`)
El cubo camina a 8 m/s entre las cajas, salta, se agacha y se para. Se mide la caja que sale más rápido **de costado**
(lo que gana cayendo no cuenta).

| Cajas | La más rápida de costado | Achatadas |
|---|---|---|
| Chicas y livianas | 9 m/s | 13 de 42 |
| Una pila alta de medianas | 34 m/s | 3 de 24 |
| Autos | ninguno se movió de costado | 2 de 6 |
| Una pared de medianas | 36 m/s | 5 de 40 |

- **Las patadas**: lo chico sale más o menos a la velocidad del cubo; las medianas, hasta 36 m/s, más de cuatro veces.
  Un pie recorre su paso en 0,3 s, así que va bastante más rápido que el cubo. **Falta decidir qué hacer con esto.**
- **La lluvia encima**: nada sale de costado a más de 9,5 m/s. No acható ninguna (caen sobre el techo).
- **Contra lo fijo**: el eje del cubo queda a 4,60 m del edificio y de la pared (el radio del cilindro); pegado al
  edificio gira los 180° enteros; yendo en diagonal contra la pared se desliza 17 m a lo largo.
- **Arrancando 5 cm metido** en el edificio y caminando contra él, el motor lo saca: queda a 4,60 m. Con el «pruebo y
  deslizo» a mano lo atravesaba entero.
- **Forcejeando 6 s contra la esquina** del edificio, cambiando de costado y girando: lo más que se mete es 1,7 cm y no
  pasa. El paso de física más lento, 4,7 ms.
- **El dash** recorre 12,6 m en el piso y 12,1 m en lo alto de un salto (la perilla dice 12). Sin dirección no hace
  nada. **Volando** con la barra entera sube hasta 23 m.

## Lo que encontré armándolo
Con la física sincronizada, poner la posición del cuerpo desde afuera no alcanza: el cuerpo la pisa con la suya. Por eso
el cubo guarda dónde está y se lo pone con `put`.
- **Un cuerpo cinemático que se pone en otro lugar barre lo que hay en el medio**, a la velocidad de ese salto. Los pies
  cruzaban 22 m en un paso y las cajas salían a 430 m/s. Por eso, para ponerlos en un lugar, se apaga la sincronización
  un instante (`place_now`, `put`); y en el aire los pies se juntan debajo del cubo de a poco.
- **Un cuerpo entra a la física donde está al agregarlo al árbol.** Los pies nacían en el origen del mundo y estaban ahí
  un paso entero: una caja que estuviera justo ahí salía a 143 m/s. Ahora nacen en su lugar.
- **Una prueba de movimiento que arranca tocando algo no lo cuenta como choque.** Con el cilindro apoyado justo en el
  piso, lo atravesaba y caía sin fin. Se prueba levantado 5 cm.
- **Las cajas nuevas no pueden nacer encimadas**, ni con las viejas ni entre sí: el motor las separa a lo bruto (una
  caja a 500 m/s con el cubo quieto). Las viejas se sacan antes y las chicas van en una grilla.
- **Saltear lo suelto de a uno con pocas vueltas** hacía que una pila de más cajas que vueltas frenara al cubo como una
  pared.
- **Un «pruebo y deslizo» escrito a mano pelea con el motor.** El cubo era un `AnimatableBody3D` (va adonde se lo pone y
  nada lo frena) con su propia prueba de movimiento. La prueba era ciega a lo que ya tenía encimado: en una esquina
  quedaba 1 cm adentro y de ahí atravesaba el edificio. Y para saltear lo suelto daba hasta 256 vueltas por movimiento,
  que bajaba los FPS. Con `CharacterBody3D` y la capa de lo fijo, las dos cosas desaparecen.
