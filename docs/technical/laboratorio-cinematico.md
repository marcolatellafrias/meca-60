# El laboratorio cinemático

**Experimento** (13/11/2026). `game/kinematic_lab/`. Fila **Laboratorio cinemático**; test `kinematic_lab_look`.
**La meca cinemática está en pausa** ([[meca-cinematica]]) hasta que este experimento diga cómo tiene que tratar lo
suelto. El usuario: «un cubo alargado que se mueva con caja en el piso, y así yo pruebo los distintos approaches de
interacción de cinemático con físico… vamos por partes. Primero definimos cómo actúa el exterior… después vemos cómo
hacemos que funcione con paquetes y con el giro».

## Qué hay
- **El cubo** (`KinematicPillar`): una caja de 6 × 12 × 6 m sobre dos pies (piernas de 6 m), cinemática y poseíble con la O.
  - Se mueve con WASD, gira con el mouse (con tope de velocidad y de aceleración), salta con espacio y hace dash con
    Shift. **No corre**: para esquivar está el dash.
  - **Moverse, lo más simple** (el usuario: «quiero dejar el sistema lo más simple que se pueda… que sea una sola
    velocidad»): una velocidad y el **tiempo para llegar** a ella, el mismo para arrancar y frenar (0: al instante), y
    cuánto se controla en el aire.
  - **Cuatro configuraciones de un toque**, botones arriba del F1: Instantánea (por defecto), Casi instantánea (0,15 s),
    Pesada (6 m/s, 0,6 s, medio control en el aire) y Sin control en el aire. Cada botón **escribe** las perillas; lo que
    manda son las perillas.
  - **Con movimiento instantáneo, el dash dura lo que dura `dash_hold`**: después la velocidad vuelve de golpe a la
    pedida. Con 0,25 s lo corre 6,9 m, en el piso y en el aire.
  - Con Ctrl se agacha: su alto baja de a poco hasta el 60 %. No se para si algo que lo frena está encima.
  - Lo fijo siempre lo frena.
  - Las perillas están en el F1 (`PillarSettings`).
- **La locomoción de la meca futura** se prueba con el cubo (el usuario: «empezar a trabajar en todo lo de locomoción de
  la meca futura, pero con este cubo»):
  - **El dash, con Shift** (era la Q mientras Shift corría): un impulso hacia donde apretás, el mismo en el piso y en el aire. **Sin dirección no pasa
    nada.** Tiene su barra, que se llena sola.
  - **Lo que hace de roce**: el cubo no tiene fricción con el piso. Lo frena moverse, que lleva la velocidad a la
    pedida. Por eso, durante `dash_hold` (0,25 s) después del dash, moverse no lo frena.
  - **El vuelo**: en el aire, espacio otra vez empuja para arriba mientras quede su barra, que se llena apoyado. Las dos
    barras son separadas, y se ven en el cartel de poseer, abajo a la derecha.
  - **Las toberas** (`PillarNozzles`), de placeholder: cuatro abajo que echan al volar, y cuatro a los costados que
    echan un fogonazo del lado contrario al dash.
  - **El F1 tiene pestañas**: Moverse, Girar, Saltar y volar, Dash, Agacharse y Con lo suelto.
  - Medido (`kinematic_lab_moves_look`), con el movimiento de antes (arrancar y frenar con tope): el dash en el piso
    lo corría 21,6 m y en lo alto de un salto 29,4 m. Sin dirección no hace nada. Volando con la barra entera sube hasta 34 m en 2 s.
- **Con qué choca cada cosa** (13/11/2026, lo charlado con el usuario):
  - **Contra lo fijo del mundo** (edificios, paredes, el piso), **un cilindro** de 4,6 m de radio, más grande que el
    cubo, del piso al techo. Girar nunca lo traba y en las esquinas se desliza. Se prueba sólo contra lo fijo: lo
    suelto no lo frena nunca. En la parcela hay un edificio y una pared larga para probarlo.
  - **Contra lo suelto, lo que se ve, por el motor y sin reglas extra**: la caja de arriba empuja lo alto, y **los pies**
    (`PillarFeet`), que tienen choque de verdad, **patean** de costado.
  - **Lo que queda debajo de algo suyo que baja se achata** (un pie, o la caja al agacharse o al caer): suena, larga polvo
    y desaparece. No se aprieta contra el piso: eso era lo que hacía explotar al motor. Para un pie, «debajo» es más
    abajo que su medio. **Los personajes todavía no se achatan**: falta ver cómo muere uno.
  - **Entre los pies queda libre.**
  - *Las cuatro reglas a mano que se probaron antes (Jolt puro, topadora con tope, atraviesa y empuja, lo suelto lo
    frena) se sacaron. La del tope arrastraba las cajas como un imán y las hacía saltar con el cubo: medía la velocidad
    de la caja respecto del cubo, y un cubo que se aleja es lo mismo que una caja que se aleja.*
- **La K elige las cajas, una configuración por vez:**
  1. Chicas y livianas sueltas (60 cm, 30 kg).
  2. Una pila alta de medianas (1,6 m, 300 kg).
  3. Grandes y pesadas, como autos (2 × 1,6 × 4,2 m, 1500 kg).
  4. Una pared de medianas.
- **La N**: una lluvia de seis cajas de la configuración de ahora, encima del cubo.

## Lo medido (13/11/2026, `kinematic_lab_look`)
El cubo camina a 8 m/s entre las cajas, salta, se agacha y se para. Se mide la caja que sale más rápido **de costado**
(lo que gana cayendo no cuenta).

| Cajas | La más rápida de costado | Achatadas |
|---|---|---|
| Chicas y livianas | 9,0 m/s | 13 de 42 |
| Una pila alta de medianas | 29,7 m/s | 7 de 24 |
| Autos | ninguno se movió de costado | 2 de 6 |
| Una pared de medianas | 23,0 m/s | 6 de 40 |

- **Las patadas**: lo chico sale más o menos a la velocidad del cubo; las medianas, hasta 30 m/s, casi cuatro veces.
  Un pie recorre su paso en 0,3 s, así que va bastante más rápido que el cubo.
- **La lluvia encima**: nada sale de costado a más de 8,2 m/s. No acható ninguna (caen sobre el techo).
- **Contra lo fijo**: el eje del cubo queda a 4,61 m del edificio y de la pared (el radio del cilindro); pegado al
  edificio gira los 180° enteros; yendo en diagonal contra la pared se desliza 17 m a lo largo.
- El cubo nunca se frena con lo suelto: avanza lo mismo (49 m) con cualquier configuración.

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
