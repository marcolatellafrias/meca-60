# El laboratorio cinemático

**Experimento** (13/11/2026). `game/kinematic_lab/`. Fila **Laboratorio cinemático**; test `kinematic_lab_look`.
**La meca cinemática está en pausa** ([[meca-cinematica]]) hasta que este experimento diga cómo tiene que tratar lo
suelto. El usuario: «un cubo alargado que se mueva con caja en el piso, y así yo pruebo los distintos approaches de
interacción de cinemático con físico… vamos por partes. Primero definimos cómo actúa el exterior… después vemos cómo
hacemos que funcione con paquetes y con el giro».

## Qué hay
- **El cubo** (`KinematicPillar`): una caja de 6 × 18 × 6 m apoyada en el piso, cinemática y poseíble con la O.
  - Se mueve con WASD, gira con el mouse (con tope de velocidad y de aceleración), corre con Shift y salta con espacio.
  - Con Ctrl se agacha: su alto baja de a poco hasta el 60 %. No se para si algo que lo frena está encima.
  - Lo fijo siempre lo frena.
  - Las perillas están en el F1 (`PillarSettings`).
- **La L elige cómo trata lo suelto:**
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
