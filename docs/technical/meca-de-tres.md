# La Meca de tres

`game/tool_mech/` · fila **Meca de tres** (la segunda del sandbox, al lado de la del vórtice) · ver [[dos-paradigmas]],
[[cabina]], [[armamento]], [[meca-cinematica]]

**Una meca de ejemplo con elementos concretos** (15/11/2026), para ir cerrando los controles de los tres pasajeros.
El usuario: «hagamos un ejemplo de una mecha con elementos concretos… vamos a ir cerrando entonces todos los controles
que van a tener los tres pasajeros que se sienten en las tres sillas». **Por ahora se maneja entera poseyéndola desde
afuera** (la O; «preocupate que si yo poseo la meca y aprieto los botones necesarios, puedo hacer funcionar todos los
controles»): los puestos de adentro se hablan con la sesión Interior.

Es la meca de siempre (`ToolMech extends Mech`): **cinemática**, con la cabina cuadrada de tres (la del medio, las
piernas; ver [[cabina]]), y lo suyo:

## La energía común — `MechEnergy`
Una sola para todos ([[armamento]]: «la energía es la estamina de la meca»). La gastan el dash, el salto, levitar, el
taladro y el cañón. Se recarga sola (14 % por segundo) desde 0,8 s después del último gasto. **Vacía, la meca queda
aturdida 2,5 s**: no camina, no gira, no tira. *El máximo que baja con el uso y cambiar la batería, después.*

## Las piernas
El movimiento de la cinemática ([[meca-cinematica]]): caminar, girar, agacharse, saltar, el dash (Shift con una
dirección) y **levitar**, que es su vuelo (espacio otra vez en el aire): la mejora de **propulsores en las pantorrillas,
atrás**, que no se modelan. El dash, el salto y levitar, además de sus barras, gastan energía.

**El dash, una decisión** (el usuario, por Jefes: «diseñar todo para un dash… que cueste más energía»): gasta **el 25 %
de la energía común** (primero fue 40 %; el usuario: «me parece mucho… va a estar moviéndose, haciendo ataques»). Y entre dash y dash está **la espera de la
cinemática** (`dash_cooldown`, 1 s desde que termina uno, en el F1): aunque sobre energía, no salen dos seguidos. Shift
sólo cobra si el dash sale de verdad (`KinematicMover.dash_ready()`).

Sus brazos, desde el 16/11/2026, son los de cualquier meca con lo que dice su `loadout` (ver [[brazo]], «Lo que lleva
en la punta»): los dos discretos, con la placa del acorazado.

## El taladro, brazo derecho — `DrillTip`
Un brazo discreto (`PoseArm`) con una mecha en vez de mano (la sierra, `SawTip`, anda igual). El usuario: «con el clic derecho… lo cargas y con el otro
clic… lo usas, porque no lo puedes usar de una porque tarda en agarrar velocidad… su propia barra, y mientras más tiempo
lo cargas… más energía gasta».
- **Cargar** (mantenido): la mecha toma velocidad (a fondo en 1,4 s) y gasta energía de a poco, más cuanto más gira.
  Suelto, se frena sola en 3 s.
- **Descargar**: el directo de siempre, al frente, sin apuntar (es cinemático). Lo que toca recibe el empujón del puño
  por un factor que va de 0,4 (casi quieta) a 2,6 (a fondo). Pide que gire por lo menos un 15 %. Después del golpe,
  gira un 30 % de lo que giraba.

## El cañón de energía, brazo izquierdo — `CannonTip`
**En lugar del antebrazo**, como el de la jaula (hasta el 16/11/2026 era una caja y un caño fino después de la mano).
El usuario: «un cañón que dispare, que tenga varios modos de disparo… simple, varios disparos chicos, uno que barra y
otro que sea un super disparo»; «que se controle con una palanca y que no sea tan controlable… que se mueva como el de
los músculos, pero sin la colisión».
- **La palanca** dice adónde apuntar (35° a cada lado, de 35° abajo a 30° arriba) y **queda donde la dejan**. **El
  brazo la sigue con un resorte con freno**: llega en medio segundo y se pasa un poco. Atraviesa todo (es discreto). El
  brazo va casi estirado, así el caño, que es el antebrazo, mira adonde apunta.
- **Cada tiro lo patea** para arriba y un poco de costado: el retroceso. La ráfaga sube sola si no se la corrige.
- **Los modos**:
  - **Simple**: un tiro mediano por apretada (6 % de energía; uno cada 0,3 s).
  - **Ráfaga**: mantenido, tiros chicos seguidos y un poco abiertos (1,2 % cada uno, 11 por segundo).
  - **Barrido**: mantenido, un rayo de 90 m que empuja lo que toca (32 % por segundo); se barre con la palanca.
  - **Súper**: mantenido, carga a fondo en 1,2 s (30 % por segundo; ya cargado, 8 %); al soltar, un tiro grande según
    la carga y una patada grande. *Que tire a la meca para atrás, después: a la cinemática todavía no la mueve un
    golpe.*
- **Los tiros** (`EnergyBolt`) van derecho y a lo primero que tocan le dan un impulso. Si tocan una pieza de una meca
  (un pie), el empujón va a la meca. **Sólo locales**: todavía no van por la red.
- **La costura con lo que lleva vida** (`EnergyBolt.lands`, para los tiros, el rayo y el taladro): además del empujón,
  si lo que recibe (o la meca de la pieza tocada) tiene `take_hit(strength, at, source)`, se lo dice: cuánto empujó, dónde
  y con qué («cañón», «rayo», «taladro»). Cuánta vida saca lo decide quien recibe (un jefe; lo pidió la sesión Jefes).

## Las placas de blindaje — `ArmorPlates`
El usuario: «paneles para brazos y piernas de armadura»; «la placa de blindaje me refiero». Sólo se ven: una funda de
chapa más oscura alrededor del medio del muslo y la canilla, con una franja en cada punta. *Hasta el 16/11/2026 también
en los brazos; ahora los brazos llevan la placa del acorazado, la misma en todas las mecas.*

## Las teclas, poseyéndola — `ToolMechKeys`
- **Piernas**: WASD · el mouse gira · Shift con una dirección, dash · espacio salta, y en el aire otra vez, levita ·
  Ctrl se agacha.
- **Taladro o sierra**: clic derecho mantenido carga · clic izquierdo descarga. **Si no lleva**, el brazo de las
  piñas: clic izquierdo, un directo; clic derecho, un gancho.
- **Cañón**: las flechas mueven la palanca · 1 simple, 2 ráfaga, 3 barrido, 4 súper · F, el gatillo.
- G / X, el ascensor. Abajo a la derecha, la energía, el modo, la carga del súper y la del taladro.

## Cómo se los imagina el usuario adentro (todavía no)
Sentado, **la cámara queda trabada mirando al frente** y se elige qué hacer **con clic en lo que se tiene adelante**.
El movimiento: **una palanca de dos ejes que queda trabada** donde se la dejó (para poder seguir caminando mientras se
aprieta el dash), y **el dash, el salto y levitar, botones aparte** en el tablero. El cañón: tres o cuatro botones de
modo y su palanca. El taladro: un botón que carga y otro que ataca. *Esto cambia lo de [[armamento]] («el movimiento: te
conectás», el mouse que gira el cuerpo sobre la silla); lo de adentro, con la sesión Interior.*

## La parcela — `ToolMechArchetype`
La meca, la de práctica a 34 m adelante (más lejos que en la de siempre: con el brazo estirado, la boca del cañón
quedaba adentro de su caja, y desde adentro un tiro no la toca) y nueve cajas sueltas de 2 m, adelante a la derecha.
Paneles: la cinemática (F1), la cabina (F2), los brazos discretos (F3), las piernas (F4).

## Test
`tests/tool_mech_look.tscn` (unos 25 s, sin el sandbox): la maneja por código. Tira en los cuatro modos (simple y súper
a la de práctica, ráfaga y barrido a las cajas) y carga y descarga el taladro contra la de práctica. Imprime la energía
y cuánto se movió cada cosa. Medido (15/11/2026): con el simple, la de práctica se corre 0,5 m; la ráfaga mueve 3
cajas y el barrido 4; con el súper cargado, la de práctica se corre 6,7 m y con el taladro a fondo, 16,8 m. La energía
baja a 0,54 después del barrido.

## Lo que falta
- Los puestos de adentro (con Interior y Tableros).
- Que el súper y los golpes muevan a la meca cinemática.
- Los tiros por la red.
- Las perillas en un panel F, si hace falta tunear: hoy son constantes en cada archivo.
