# Los recursos de la meca

`game/supplies/` (el dibujo, `SupplyLook`) · `PackageArchetype` (el cuerpo que se agarra, en la misma carpeta) · fila
**Recursos** · ver [[filas]]

Lo que se busca en el mundo y se trae a la meca. **Todo es un cubo de 63 cm** que se agarra siempre igual, de un punto
en el centro de cada cara (el usuario, 13/11/2026: «no vamos a tener paquetes dobles ni más largos… una celda de tamaño
único»). El lugar de la meca donde va cada uno tiene **el mismo formato de cubo** (empotrado o no, se verá con los
tableros).

## Lo que hay hoy (sólo se agarran: todavía no se enchufan en nada)
| Recurso | Se lleva | En la meca |
|---|---|---|
| **Batería** | la batería misma: colorada, como una de auto, con sus polos | la misma, con su mirilla: el nivel baja; gastada, toda oscura |
| **Componente eléctrico** | el componente: una caja tipo transformador, con aletas y dos bornes | el mismo, con su lamparita; quemado, oscuro y tiznado (con chispas y humo) |
| **Misiles** | una caja de munición lisa, ocre | un cubo con nueve tubos: asoma la punta de cada misil que queda |
| **Balas** | una caja de munición lisa, gris verdosa | un cubo con una ventana: la cinta, en cuatro columnas, baja |
| **Bomba** | nueve cartuchos de dinamita atados (como la TNT de Minecraft) | no se enchufa: la tira el jugador a pie |

El aspecto es «así nomás», en arcilla: después se remodelan y se les pinta la textura con píxeles (un sistema para
editar cada cara dentro del sandbox). Lo que tiene que valer para los que se agreguen, en el comentario de `SupplyLook`:
**que se sienta una caja** (ni armazones ni cosas sueltas sobre una base), **down to earth** (colores tranquilos, poco
contraste, estereotipos) y **low poly**.

## La mecánica acordada (falta hacerla)
- Son **físicos** mientras se llevan. Cerca de su lugar en la meca aparece **un indicador** (el enchufe de Half-Life 2);
  al soltarlo ahí **se va de las manos y se acomoda solo**: pasa de físico a ser parte de la meca.
- **Cada hueco acepta sólo su tipo.**
- **La batería y el componente** son lo que queda puesto. **Puesto, no se saca hasta que se gasta o se quema**; para
  poner uno nuevo hay que **sacar antes el viejo, agarrándolo**.
- **La munición es distinta**: la caja que se lleva no es lo que queda en la pared. Se apunta la caja al cubo de la meca
  y **se recarga entera**.
- **El gastado**, sacado y tirado al suelo, **se desvanece al rato**: no queda estorbando.
- **El estado se lee mirándolo, sobre todo puesto en la meca** (llevándolo importa menos): el nivel, los misiles que
  quedan, oscuro y con chispas si se quemó.
- **La bomba** la tira el jugador a pie. Lo que tira la meca son misiles (más adelante, de varios tipos).

## Lo que quedó de antes
`PackageArchetype` vino de character-parametric con los paquetes de una ciudad (el televisor, el sillón, la caja
fuerte, un cajón de botellas…). El 13/11/2026 se borraron sus bosquejos, el cajón y su contenido, las cajas largas de
prueba y su ida y vuelta a Blender: hoy su catálogo son estos cinco cubos. El sistema de agarre
(`GrabbableInteractable`) no se tocó: ya sabía de módulos de 63 cm.
