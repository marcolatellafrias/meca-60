# El sandbox — buenas prácticas

`game/sandbox/`. Filas de parcelas para probar una cosa por vez. Lista de filas, en [[filas]].

## Cómo está ordenado
**Supercategoría → fila → subcategoría → parcela.**
- **Supercategoría** (`SandboxSuper.Id`): una por módulo (Meca, Interior, Personajes, Mundo, Arte, Red, Jefes). Bloque contiguo,
  piso apenas teñido, su nombre a la izquierda. **Obligatoria**: sin ella la fila no compila.
- **Fila** (`SandboxRow`): una categoría, con una o varias parcelas.
- **Subcategoría** (`row.group(...)`): parcelas juntas dentro de la fila, con el suelo de otro tono.
- **Archivada** (`row.archive()`): va a la fila **Archivo** al final de su bloque, con piso azul pizarra, como una
  subcategoría. No hay supercategoría de archivo: lo archivado queda cerca de lo suyo.

## Agregar una fila
Va en el archivo de filas **de tu módulo** (`MechRows`, `CharacterRows`, `WorldRows`, `ArtRows`, `SupplyRows`,
`NetworkRows`, `BossRows`), nunca en `design_sandbox.gd`:

```gdscript
SandboxRow.new(SandboxSuper.Id.MECH, "Meca jaula") \
    .add(SandboxRow.Build.NEAR, [CageMechArchetype.new()]) \
    .panel(KEY_F1, "la meca jaula: moverse…", CageMovesPanel.new())
```

Un módulo nuevo agrega una línea en `SandboxCatalogue.rows()`.

## Cuándo se arma (obligatorio al agregar)
- `Build.NEAR`: la primera vez que uno se acerca. Es lo normal.
- `Build.ON_KEY`: sólo con la **R** parado en ella. Es para lo pesado (una ciudad entera) que no debe armarse por pasar al lado.

De lejos (a más de 90 m), lo armado se esconde y se pausa, y en su lugar va un cubo gris de su medida. **Una sin armar
también tiene su cubo** apenas deja de estar cerca: del tamaño de su parcela y del alto que diga su arquetipo
(`far_height()`, por defecto la mitad de su lado más corto, entre 1 y 12 m). Las parcelas no dependen entre sí.

## Los carteles
Parados y **siempre de frente** a quien mira (`SandboxLayout.signpost`). El alto de la letra dice la jerarquía:
- **supercategoría**: 1,8 veces la fila más alta de su bloque, donde el bloque empieza;
- **fila**: el 10 % de su fondo, entre 0,8 y 4 m;
- **subcategoría**: 0,7 del de su fila;
- **parcela**: el 4 % del ancho de su zona, entre 0,25 y 2,5 m, sin pasarse de ese ancho.

## Zona y bordes
- **Bordes invisibles** en el borde de la parcela (no en el de la zona): lo físico de adentro no sale.
- **Zona de interacción**: igual en los cuatro lados, el 20 % del lado mayor, entre 3 y 15 m (`SandboxParcel.pad_for`).

## Panel chico o panel F
- **Panel chico** (`SandboxKey`, en `keys()` del arquetipo o en `row.key(...)`): sólo **acciones transitorias de
  prueba**, como tirar una bola, pegarle, subirse, un interruptor de vista o pasar por pocos estados. **Nunca algo que se
  guarda.**
  - `action` hace algo, `toggle` prende o apaga, y `cycle` pasa por **hasta 8** estados.
  - Cada una lleva su **peso**: `MAIN` (ámbar, va primero; a lo sumo tres por parcela) o `NORMAL`.
- **Panel F** (`TunerPanel`): **lo que se guarda**, los sliders, los ajustes finos y lo que tiene muchas opciones.
  También una acción transitoria que se vuelve compleja (muchos empujes distintos, con sus parámetros) pasa a un panel.

## Paneles F: tres alcances
- **De parcela** (`row.parcel_panel(...)`) y **de fila** (`row.panel(...)`): de **F1 a F7**.
- **Globales** (`SandboxCatalogue.global_panels()`): de **F9 a F12**.
- **La F8 nunca**: en Godot detiene el juego.

En el panel chico, el alcance lo dice el bloque donde aparece (ESTA PARCELA, ESTA FILA, SIEMPRE). Hay tres colores en
total: gris para lo normal, ámbar para lo principal y celeste para las F.

## Teclas reservadas (`SandboxKey.RESERVED`)
- WASD, espacio, shift, Ctrl, E y Escape. Con el ente, shift corre; dos toques seguidos dan el turbo (×4) y tres el
  segundo turbo (×16), para cruzar el sandbox (`CharacterRigidBody3D.turbo_factor`).
- **R** regenera (o arma) y **C** copia.
- **V** prende el modo creativo; la **B** corta también, y la **B** larga cambia entre ente y cuerpo.
- **I** el inspector, **O** poseer y **T** la vista de lo poseído.
- **Tab** oculta toda la pantalla, y la vuelve (`UIState.hide_screen`): se apaga el dibujo de 2D en la ventana, así
  que no hay panel que se escape ni que tenga que anotarse. Cierra las F abiertas; abrir cualquier F, la pausa o la
  consola la devuelve.

El panel chico tampoco usa F1–F12.

## Las reglas se chequean
`SandboxCatalogue.check` las revisa al arrancar:
- una tecla reservada o repetida;
- una F fuera de rango;
- dos paneles con la misma tecla que pueden abrir en el mismo lugar;
- un ciclo de más de 8 estados;
- más de tres teclas principales;
- filas sin nombre o con el nombre repetido.

Los problemas salen **en rojo, arriba a la izquierda**, y lo que choca no se monta. `tests/sandbox_check.tscn`
(headless) falla si hay alguno.

## La bola
`TestBall.keys(self)`: la **J** tira (es la principal) y la **K** pasa por los tiros (`ball_shots`, o `ball_pushes`).
