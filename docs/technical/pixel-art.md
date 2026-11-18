# Pintar con píxeles

`game/pixel_art/` · fila **Píxeles** · test `tests/pixel_art_look.tscn` · ver [[filas]], [[recursos]]

**Es un experimento** (13/11/2026): el flujo para modelar en Blender, traerlo a Godot y pintarle la textura con píxeles,
cara por cara, dentro del sandbox. Va a valer para todo (los recursos, las mecas, los personajes, el mapa, la base);
los primeros candidatos son las cajas de munición, que se dejaron lisas para esto. Nada de esto está sentado.

## El flujo
1. **Se modela en Blender en quads, sobre la grilla de píxeles** (un píxel = 63 cm / 16 = 3,9 cm): las medidas en
   píxeles enteros. Sin UVs, sin nada más. Se exporta `.glb` (con un material de color por parte: es el color de base).
2. **Godot detecta las caras rectas** (`PixelFaces`): el `.glb` llega todo en triángulos, y se juntan los triángulos
   vecinos que están en el mismo plano. Un quad vuelve a ser un quad; dos quads vecinos en el mismo plano son una cara.
   Cada cara recibe una grilla de píxeles apoyada en su contorno, con «arriba» hacia arriba del mundo.
3. **Se pinta en el sandbox** (`PixelPaintPanel`, F1 en la fila Píxeles): mirando una cara, F1 la abre aplanada y
   grande, como un editor de pixel art; clic izquierdo pinta, clic derecho toma el color, × vuelve al color del
   material, rellenar y deshacer. Con el panel abierto, un clic en otra cara del modelo la elige. Paleta chica y
   tranquila.
4. **Se guarda solo** al soltar cada trazo, en `game/pixel_art/painted/<nombre>.json`.
5. Al abrir, `PixelModel` rearma el atlas (un rectángulo por cara) con lo guardado y dibuja el modelo con él.

*Elegido el 13/11/2026 entre cuatro enfoques*: que Godot detecte las caras (este), que Blender desenvuelva cada quad
con un script, uno mixto (Blender marca sus quads y Godot los respeta) y sin textura (un color por cara). Y entre
pintar directo en 3D o en un panel plano: **el panel plano**.

## Dos modos de cara: cuadrícula y estirada
El usuario (13/11/2026): «si un chamfer está estirado, sigue siendo un quad… los píxeles se estiran con ese skew… me
gustaría controlar si quiero una cosa u otra». Hay dos, y se eligen **por modelo** (`PixelModel.stretch_all`) y **por
cara** (`face_modes`, que pisa al del modelo); los dos se guardan con la pintura. En el panel F1, dos botones: «esta
cara» y «todo el modelo».

| | Cuadrícula (por defecto) | Estirada |
|---|---|---|
| El píxel | cuadrado, del mismo tamaño en todo el modelo | se deforma con la cara: más angosto en el lado corto de un trapecio |
| Una cara que no mide píxeles enteros (el chanfle, 2,83) | la última fila queda cortada | se redondea: 3 filas un poco más altas |
| Los costados en diagonal (las puntas del chanfle, la hipotenusa) | escalera de píxeles cortados | las columnas se inclinan con el lado: ningún píxel cortado |
| Un triángulo | el rectángulo que lo contiene; lo de afuera, apagado (rayado en el panel) | las filas paralelas a la base y las columnas juntándose en la punta, como un abanico |
| Más de cuatro esquinas (una L) | igual que siempre | no se puede: queda en cuadrícula |
| Empalme con la vecina | si las dos miden píxeles enteros, siempre | sólo donde los dos lados opuestos tienen la misma cuenta (ver abajo) |
| Remodelar | conserva lo que se superpone | si la cara cambia de tamaño, todos sus píxeles se corren: pierde lo suyo |

**Por qué un trapecio no puede empalmar de los dos lados**: el chanfle del frente mide 16 píxeles abajo (donde toca el
frente) y 12 arriba (donde toca el techo). La grilla estirada tiene la misma cantidad de columnas arriba y abajo: se
elige **la del lado más largo** (16), que empalma con el frente; arriba quedan 16 columnas angostas contra 12 del techo.
Es geometría, no un detalle del código: para empalmar con los dos habría que partir el chanfle o usar otra densidad.

**Cambiar de modo no pierde lo pintado**: cada píxel nuevo toma el color del píxel viejo donde cae su centro, y lo de
antes queda guardado (volver al otro modo lo recupera tal cual).

**Cómo se dibuja la estirada**: un quad chico por píxel, con las esquinas de su píxel en el atlas. Con el quad entero de
dos triángulos, un trapecio se vería doblado en la diagonal (la textura «afín» de cada triángulo); así el doblez queda
dentro de un píxel de un solo color y no se ve. Cuesta más triángulos (16 × 3 píxeles = 96): para modelos low poly no
pesa.

**Tener los dos complica poco**: comparten la detección, el atlas, la memoria, el panel y el guardado. Lo distinto es
dónde cae cada píxel (`PixelFace.centre`, `pixel_at`), cómo se arma la malla y cuántos píxeles tiene la cara.

## La densidad: 16 píxeles por cubo de 63 cm
Unos 25 píxeles por metro: el cubo de un recurso es de 16 × 16 por cara. **Una sola densidad para todo el juego**, así
un píxel mide lo mismo en una caja, en la meca y en el piso. El test compara 8, 16 y 32 (captura 7): 8 se ve tosco
para una etiqueta, 32 ya es mucho dibujar por cara. Se cambia en `PixelModel.PIXELS_PER_CELL`; lo pintado es de una
densidad (cambiarla lo deja sin lugar).

## Cómo se evitan las costuras
- **Filtro «más cercano» y sin mipmaps**: un píxel nunca se mezcla con el de al lado ni con el de otra cara.
- **Un borde de un píxel alrededor de cada rectángulo del atlas** que repite su orilla: un redondeo en la arista no
  toma el color de otra cara. Los píxeles que la cara no toca (una cara que no es un rectángulo) toman el de su vecino.
- **Modelar sobre la grilla**: si las caras miden píxeles enteros, la grilla de cada una arranca en su esquina y el
  dibujo sigue de una cara a la vecina sin saltos (la franja de la captura 4 da la vuelta). Lo inclinado (un chanfle)
  tiene su grilla aparte y ahí el dibujo no empalma.

## La memoria: remodelar sin repintar
El usuario (13/11/2026): «si cambio algún detallito de un modelo… no quiero volver a hacer todas las texturas».

**Lo pintado no se guarda por cara ni por atlas, sino por píxel anclado al modelo**: la clave de cada píxel es la
dirección de su cara y la posición de su centro en el espacio del modelo. Al remodelar se vuelven a detectar las caras
y cada píxel busca su clave:
- una cara que no cambió **conserva todo**;
- una que se agrandó o achicó conserva **lo que se superpone**;
- una nueva sale **del color de su material**, para pintarla;
- una que se corrió (otra posición u otro ángulo) **pierde lo suyo**;
- **lo que ya no tiene lugar no se borra del archivo**: vuelve si se vuelve a la versión anterior.

El orden de las caras y el atlas no importan: se rearman cada vez. En el test, la caja con la manija más larga y una
chapa nueva conserva 1400 de sus 1408 píxeles (los 8 que se pierden son la manija, que cambió de tamaño).

## Para quien lo usa
- **Sombreado suave** (`smooth_normals`, antes de armar): las caras pintadas de las cabezas (ver [[personajes-traidos]]).
- **Lo de quien lo usa** (`extra`), guardado con la pintura: el giro de la cabeza.
- **Leer un guardado sin armar el modelo** (`PixelModel.peek`): su densidad, antes de armarlo.

## Lo que quedó sin resolver
- **Una cara que se corre pierde lo suyo** (por ejemplo, una pared que se hace un píxel más gruesa). Se podría buscar la
  clave también corrida por la normal, o «llevar» la pintura de una cara vieja a la nueva más parecida.
- **Lo inclinado y lo curvo**: en cuadrícula, un chanfle tiene su grilla aparte; en estirada, empalma de un lado solo
  (ver los dos modos). Un cilindro low poly es una cara por lado.
- **En estirada, una cara que cambia de tamaño pierde lo suyo**: se podría guardar esa cara por su posición relativa (de
  0 a 1) en vez de por el lugar de cada píxel.
- **Los huérfanos se acumulan** en el archivo: falta un botón para limpiarlos cuando una versión se da por buena.
- **Para el juego** habría que hornear el atlas a un PNG y la malla con sus UVs (hoy se arma al cargar; para pocos
  modelos chicos no pesa).
- **Modelos iguales comparten pintura** por su nombre: está bien para los recursos; para variantes (la misma caja de otro
  color) faltan capas o paletas.
- Falta **dibujar sobre el modelo** (el usuario eligió el panel), las **simetrías** (pintar una cara y que se copie en la
  opuesta) y los **sellos** (una etiqueta que se repite).

## El código
| Archivo | Qué es |
|---|---|
| `pixel_faces.gd` · `PixelFaces` | Detecta las caras rectas y las acomoda en el atlas. |
| `pixel_face.gd` · `PixelFace` | Una cara: sus triángulos, su grilla, qué píxeles toca. |
| `pixel_model.gd` · `PixelModel` | El modelo pintado: el atlas, la malla, la memoria, guardar y leer. |
| `pixel_paint_panel.gd` · `PixelPaintPanel` | El panel F1: elegir la cara, la paleta. |
| `pixel_grid.gd` · `PixelGrid` | La cara aplanada donde se pinta. |
| `pixel_art_archetype.gd` · `PixelArtArchetype` | La parcela: el cubo de 63 cm y la caja de Blender; **N** cambia a la versión 2. |
| `models/caja.glb`, `caja_v2.glb`, `cuna.glb` | La caja de prueba y una cuña con dos caras triangulares; las arma `tools/pixel_art_modelos_prueba.py` en Blender. |
