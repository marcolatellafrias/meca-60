# Lo traído de character-parametric

`game/character/`, `game/interactables/`, `game/objects/`, `game/common/`… y la frontera en `game/character_port/`
(su `LEEME.md` dice qué se trajo y dónde se cortó). **Ya es código de la meca**: se edita y se simplifica.

- **El jugador** es el personaje de allá: ente (sin cuerpo, **V** vuela) o cuerpo con **B** (el gordo atlético).
- Agarrar (clic izquierdo), sentarse (**E**), empujar (**R**).
- Fila **Personajes**: los seis arquetipos, que se caen y se levantan (`CharacterGetUp`). Fila **Objetos**: paquetes y
  una silla.

## El cuerpo (13/11/2026)
Seis arquetipos (gordo, musculoso, flaco alto, chico, viejo, gordo atlético), cada uno con sus proporciones y sus
números de juego (peso, fuerza, velocidad). **Nada más**: sin trajes, sombreros ni herramientas de esculpir.
- **La forma de bloques** (`BlockShape`: unos pocos metros por arquetipo, la de fábrica en `FACTORY` o la guardada en
  `block_shapes.tres`) es el cuerpo que se ve (`BlockBody`: cajas y cápsulas) y **de ella salen todas las medidas**
  (`SkeletonSizesUtil`): los huesos, la cadera, los hombros, el alto, la cápsula, la marcha. Encima, la postura y el
  andar del arquetipo (`EntityArchetype`, con lo guardado en `pose_shapes_low.tres`), y al final su tamaño
  (`body_scale`) y la lupa.
- **La cabeza** es una forma low poly (`HeadForm`: ocho lados, una arista por loop cut, sombreado suave) llevada al alto
  de la forma de bloques. El cuello nunca es más ancho que la cabeza donde entra (si no, asomaba como papada).
- **El reposo de cada hueso** (para dónde apunta) es una tabla, `CustomBonesUtil.REST`. *Antes se leía de un modelo de
  Blender, borrado.*
- *El 13/11/2026 cambiaron dos cosas al rehacer las medidas, a propósito: la postura de hombros es el ángulo que pide el
  arquetipo (la cuenta vieja lo multiplicaba por una escala, por error: de 7° a 5° en el gordo), y las cápsulas del
  ragdoll son del ancho de la caja o el miembro de cada hueso.*

Pruebas:
- `tests/people_look.tscn` (con ventana, unos 12 segundos): los seis en fila, sus cabezas de cerca, y caminando 3
  segundos (imprime cuánto anduvo cada uno y si quedó de pie). `--cabezas=0.29,0.28,…` prueba altos de cabeza.
- `tests/sizes_check.tscn` (headless, un segundo): imprime cada medida de los seis y dónde cae cada hueso. **Si un cambio
  no debería cambiar a nadie, correrlo antes y después y comparar**.

Ver también [[red]].
