# El laboratorio cinemático

**Experimento** (13/11/2026). `game/kinematic_lab/`. Fila **Laboratorio cinemático**; test `kinematic_lab_look`.
**La meca cinemática está en pausa** ([[meca-cinematica]]) hasta que este experimento diga cómo tiene que tratar lo
suelto. El usuario: «un cubo alargado que se mueva con caja en el piso, y así yo pruebo los distintos approaches de
interacción de cinemático con físico… vamos por partes. Primero definimos cómo actúa el exterior… después vemos cómo
hacemos que funcione con paquetes y con el giro».

## Qué hay
- **El cubo** (`KinematicPillar`): una caja de 6 × 18 × 6 m apoyada en el piso, cinemática y poseíble con la O.
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
- **El F1 elige cómo trata lo suelto** (pestaña Con lo suelto; **por defecto, la topadora con tope**):
  1. **Jolt puro**: masa infinita.
  2. **Topadora con tope**: nada suelto cercano sale hacia afuera más rápido que la caja, más 1,5 m/s.
  3. **Atraviesa y empuja**: no choca por Jolt con lo suelto cercano; lo saca él, por la cara más cercana.
  4. **Lo suelto lo frena**: como una pared. Al bajar, se apoya encima.
- **La K elige las cajas, una configuración por vez:**
  1. Chicas y livianas sueltas (60 cm, 30 kg).
  2. Una pila alta de medianas (1,6 m, 300 kg).
  3. Grandes y pesadas, como autos (2 × 1,6 × 4,2 m, 1500 kg).
  4. Una pared de medianas.
- **La N**: una lluvia de seis cajas de la configuración de ahora, encima del cubo.

## Lo medido (13/11/2026)
Corriendo a 14 m/s contra las cajas, después salta, se agacha y se para. Se mide la caja que sale más rápido **de
costado** (lo que gana cayendo no cuenta), en m/s, y en qué momento.

| | chicas | pila | autos | pared |
|---|---|---|---|---|
| Jolt puro | 16,6 corriendo | 17,3 saltando | 16,2 corriendo | 14,5 saltando |
| Topadora con tope | 17,6 saltando | **7,2** | 16,4 corriendo | **8,8** |
| Atraviesa y empuja | 17,6 corriendo | 18,4 saltando | 15,2 corriendo | 19,1 saltando |
| Lo suelto lo frena | 10,2 | **30,7 corriendo** | 7,9 | **27,3 corriendo** |

- **Nada quedó metido adentro del cubo**, en ninguna forma.
- **La lluvia encima**, en las cuatro formas: las cajas quedan arriba o caen al costado, y nada sale despedido de costado
  más de 9,4 m/s, ni agachándose ni parándose ni saltando.
- **El cubo frena** contra la pila y la pared en la topadora (avanza 23–24 m en vez de 85) y en la pared (12–16 m).

## Lo que encontré armándolo
Con la física sincronizada, poner la posición del cuerpo desde afuera no alcanza: el cuerpo la pisa con la suya. Por eso
el cubo guarda dónde está y se lo pone con `put`.
