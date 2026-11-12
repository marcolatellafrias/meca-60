# La meca péndulo

`game/pendulum_mech/` · fila **Meca péndulo** · ver [[filas]]

El [[cubo-pendulo]] camino a ser la meca: mismo equilibrio (el torso es un péndulo sobre su apoyo, los pies lo siguen),
con cabina de tres pisos, brazos, y correr, agacharse, saltar y volar. El cubo péndulo queda como estaba, de referencia.

## Por dentro
**Tres pisos** con la proporción del cubo (2,67 m cada uno): vidrio con parantes al frente, **la puerta atrás** (el
hueco, sin escalera todavía) y un asiento con su consola. Es dibujo. La primera persona de [[poseer]] es la del asiento
del medio.

## Los brazos
Dibujo, en guardia: el hombro y el codo son **esferas**, la muñeca un **cubo**, y los dedos **cilindros**, piezas
separadas; el pulgar va en la cara de costado del cubo. No pegan ni chocan todavía: los brazos con músculos son el paso
que sigue.

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
