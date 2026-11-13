# Análisis de lo traído de character-parametric

Pasada de **sólo lectura** del 13/11/2026, para decidir qué se limpia en la segunda etapa (después de la meca). No se
cambió código. **Cómo se hizo**: un script armó el grafo de quién nombra a quién (clases, rutas, escenas, autoloads) y
de cada archivo se leyó su tamaño, su comentario de cabecera y quiénes lo usan. **No se leyó cada archivo entero**: la
clasificación de abajo sale de eso, y los números de líneas son de `wc`.

## Los números
| | Archivos | Líneas |
|---|---|---|
| **Lo propio de la meca** (`mech`, `pose_arm`, `muscle_arm`, `line_cube`, `supplies`, `sandbox`, `arena`) | 43 | 5.650 |
| **Lo traído** | 147 | 38.000 |
| · `character/` | 67 | 21.000 |
| · `debug/` | 17 | 4.400 |
| · `interactables/` | 14 | 4.250 |
| · `sounds/` | 4 | 2.000 |
| · `net/` | 8 | 1.770 |
| · `objects/` | 4 | 1.470 |
| · `common/` | 5 | 1.200 |
| · `ui/` | 9 | 1.030 |
| · `particles/`, `city/`, `main/`, `character_port/` | 19 | 1.440 |

Lo traído es **siete veces** lo propio.

## El hallazgo principal: casi nada está suelto
Desde el juego (los autoloads, el sandbox, las escenas) **se llega a 141 de los 147 archivos traídos**. Sólo 6 archivos
(713 líneas) no los nombra nadie. O sea: la limpieza **no es «borrar lo que nadie usa»**. Es **decidir qué features no
son de este juego y cortar los cables que llevan a ellas**. Al traerlo ya se cortó lo que estaba suelto; lo que queda
está enganchado.

Lo que el código propio de la meca nombra directo es poco: `TunerPanel` (7 veces), `BoneInstantiator` (4),
`GameOptions` (4), `SeatInteractable` (3), `PhysicsLayers` (3), `MotionFrame` (2), `ParticleSystems`, `PackageArchetype`,
`GrabbableInteractable` y media docena más. Todo lo demás llega por adentro del personaje.

## En cuatro grupos

### A · Lo que la meca necesita (se queda; después se entalla)
Unas **14.000 líneas**.
- **El cuerpo que camina**: `CharacterRigidBody3D` (1.126), `CharacterIntent`, `CharacterKind`, `LocomotionCommon`, el
  vuelo creativo.
- **La animación procedural**: `IKUtil` (853), `Animations`, `AnimationModifiers`, la caminata (`WalkStyle`,
  `WalkModifier`), las pasivas, `ProceduralBoneAnimation`, el rig lógico (`CustomBone`, `CustomBonesUtil`).
- **Caerse**: `RagdollUtil` (914), `AirStyle`.
- **Agarrar y llevar**: `GrabbableInteractable` (917), `InteractionController` (818), `InteractionDetector`,
  `ArmsController` (768), `GripStyle`.
- **Sentarse**: `SeatInteractable` (694), `ProceduralSeat`.
- **Ir adentro de algo que se mueve**: `MotionFrame` (390).
- **Mirar**: `FirstPersonView`, `PossessionCamera`.
- **La red**: `SessionManager`, `NetSpawner`, `CharacterSpawner`, `CharacterNetSync`, `NetBody`, `ExclusiveClaim`.
- **La interfaz**: pausa, opciones, menú de inicio, `UIState`, la consola, el HUD de la estamina.
- **Los paneles del sandbox**: `TunerPanel` (500), `PropertyTuner` (658).
- **Partículas, sonido** (el sistema: `Sounds`, `SoundEntity`), `PackageDamage`.

### B · El aspecto del personaje: la decisión grande
*13/11/2026, la sesión de Personajes: **hecho**. Las medidas salen de cero de la forma de bloques y la postura del
arquetipo (`SkeletonSizesUtil`, de 1.273 a unas 340 líneas, ver [[personajes-traidos]]); se borraron `TorsoShape`,
`TorsoShapes` (y sus `.tres`), `ReferenceRig` con el modelo `character.glb` que leía (sus ángulos de reposo quedaron
como tabla en `CustomBonesUtil.REST`), `BodyLoop`, `FootCut`, `BlockShape.apply_to` y cinco números de arquetipo que
sólo usaba la cuenta vieja. Los seis personajes quedaron iguales, medido. **Las cabezas**: sombreado suave sobre las
mismas pocas caras, más grandes y con el cuello más grueso e inclinado (afinado «así nomás»; el usuario lo va a tunear).
**Las caras**, borradas el mismo día (`FaceLayout`, `FacePlane`, `FaceFeature`, `FaceStyle`, `FaceHair`, `BoneShape`,
la boca, los ojos y las orejas de `HeadForm`, y lo de `CharacterLook` que las elegía): no se dibujaban, y el usuario las
rehace de cero, quizá pintadas con píxeles. De `CharacterLook` quedan la semilla, la forma de cabeza y la piel.*

*13/11/2026, después: **la cabeza es su forma de cabeza low poly** (`HeadForm`): ocho lados, y a lo largo sólo los
anillos que mandan (las tapas y los cortes prendidos), con caras planas, así cada loop cut es una arista que se ve. **El
alto de la cabeza es un número**, el de la forma de bloques (`BlockShape.head_height`); la forma se lleva a ese alto y
pone el ancho y el fondo. Se borraron la cuenta vieja del alto (con el atlas, el cuello y la tapa del torso, pisada
después por la forma de bloques) y `BodyDensity`, que ya no usaba nada. **Lo que queda enchastrado**:
`SkeletonSizesUtil.create` todavía calcula un cuerpo entero a la manera vieja (el rig, la forma del torso) que la forma
de bloques pisa al final; es lo primero que tiene que rehacer la sesión de Personajes.*

*Decidido el 13/11/2026: quedan **los seis arquetipos con sus proporciones**, en **la versión simplificada**, sin trajes
ni sombreros; las caras las rehace el usuario desde cero (quizá las low poly con loop cuts). Lo que se encontró al
empezar: **el cuerpo que se ve hoy ya es el simple** (`BlockBody`: cajas y cápsulas, con `BlockShape` y la mano de
tubos). El generador de malla viejo, `GridPart` (1.973 líneas), sólo lo nombraban las orejas, que nadie llamaba: se
borró con ellas y con `FaceFeatureMesh`. Falta cortar los trajes, los sombreros y lo que cuelga de ellos, y ver qué de
`TorsoShape`, `HeadForm` y las caras todavía decide medidas del cuerpo (lo lee `SkeletonSizesUtil`).*

Unas **10.000 líneas** para generar el cuerpo paramétrico de **seis arquetipos**, con caras, trajes y sombreros de un
repartidor de Buenos Aires de 1910:
- la malla: `GridPart` (1.973), `SkeletonSizesUtil` (1.332), `ProceduralBodyUtil` (608), `BodyLoop`, `BodyDensity`,
  `BlockBody`, `TubeHand`, `ReferenceRig`;
- las formas guardadas: `Archetypes` (825), `TorsoShape`/`TorsoShapes` (663), `HeadForm`/`HeadForms` (505),
  `BlockShape`, `PoseShape`, `CharacterLook`, los cortes de pie y de cabeza;
- la cara: `FaceLayout`, `FacePlane`, `FaceFeature` y su malla (1.400 entre todos);
- lo que se lleva puesto: trajes, cinturón, sombreros, lentes, pipa (400).

Y de esto cuelgan las **herramientas para esculpirlo** (grupo C, unas 3.200 líneas de `debug/`). **Qué personaje quiere
este juego** decide el destino de unas 13.000 líneas.

### C · Lo que es de otro juego
Unas **9.000 líneas**, pero enganchado:
- *Borrado el 13/11/2026, junto con la palanca de cambios de auto (`GearShiftComponent`), que sólo él usaba. El
  «tipo de exhibición» de un personaje (`CharacterKind.is_exhibit`) queda: lo usan las figuras de la fila Personajes.*
  **`ExhibitOperator`** (1.308): un personaje de exhibición que maneja controles solo, para las vitrinas de la nave. Lo
  nombran `BoneInstantiator`, `ArmsController`, `CharacterIntent`, `CharacterKind` e `InteractionController`.
- *Borradas el 13/11/2026 (el usuario: «las herramientas, borrarlas»), con lo que sólo ellas usaban (aislar partes en
  el panel, el cono de agarre, la cámara orbital del numpad, el F3).* **Las herramientas de esculpir el cuerpo**: el
  inspector (`CharacterInspectorSource`, 873), `QuadWire`, `BlenderView`, `ModelClick`, `SkeletonDebugDraw`,
  `CharacterDebugView`, `ForceFieldGizmo`, `DebugOrbitCamera`, `ViewTuner`: unas 3.200 líneas.
- **Los paquetes de ciudad**: los bosquejos viejos dentro de `PackageArchetype` (unas 600 de sus 921 líneas), el cajón
  de botellas (`BottleCrate`, `PackageContents`: 377) y `ModelBox` (263, el ida y vuelta con Blender).
- **`HeldInteractable`** (212): el manual y el teléfono de la nave. **El manual se queda** (va a tener uso); el
  teléfono se borró (eran sólo sus sonidos). ⚠ **La pose con que el personaje sostiene la pieza quedó a medias** (lo
  dijo el usuario el 13/11/2026): ese código no es final, hay que revisarlo antes de construir encima.
- **El catálogo de sonidos** (`SoundCatalog`, 405): tiene las claves de la nave y de la ciudad.
- **`WorldSeeds`, `WorldSettings`** (90): las semillas del día y la niebla de la ciudad.
- **`game/character_port/`**: 13 archivos de **una o dos líneas** que existen sólo para que lo traído compile sin la
  ciudad, el tránsito, el clima ni la nave. Cada uno es un cable a cortar: al sacar quien lo nombra, se va.
- **`PlayerController`** (976): mezcla lo del jugador con el panel de debug, los spawns de prueba y restos de ciudad.

### D · Lo suelto
Unas **700 líneas**, y menos sueltas de lo que parecía:
- 6 archivos que ningún script nombra: `suit_style`, `suit_styles`, `bone_shape` (su cabecera ya dice «sin uso»),
  `canonical_body`, `face_feature_mesh`, `face_features`. **Pero tres de ellos los nombran recursos guardados**
  (`character_looks.tres`, `face_features.tres`, `suit_styles.tres`): se van junto con esos recursos, al simplificar el
  aspecto (grupo B). Hoy sólo se pudo borrar `canonical_body` (18 líneas).
- *Corrección (13/11/2026): la primera versión de esta nota decía que `ImpactDebug`, `Species` y `StabilityHud` no
  tenían usuarios. Estaba mal: se buscaron por el nombre del archivo y sus clases se llaman `ImpactDebugHUD`,
  `EntitySpecie` y `StabilityHUD`; las tres se usan (el controlador del jugador, el HUD y la instanciación).*

## Los controles: ojo antes de borrarlos
`ControllableInteractable` (421), `RotatingComponent` (259), `TwoAxisComponent` (69), `GearShiftComponent` (251) y
`BellowsSleeve` (48) son **los controles que se manejan con la mano** (un volante, una palanca de dos ejes, una palanca
de cambios). Vinieron por la nave, pero **las consolas de la meca van a necesitar exactamente eso**. Salvo la palanca de
cambios de auto, yo los dejaría hasta diseñar las consolas.

## Lo que criticaría de la estructura (para cuando se entalle)
- **`BoneInstantiator`** (1.642 líneas) hace de todo: arma el esqueleto, elige el aspecto, corre la animación, sigue la
  silla. Es el candidato a partirse como se partió la meca.
- **Los comentarios hablan de otro proyecto**: fechas, «el dios del juego», documentos que acá no existen
  (`docs/technical/…`, `docs/conceptual/…`).
- **Los nombres**: «exhibit», «ship», «nave», «sucursal» aparecen unas 350 veces en lo traído.
- **`UnitMesh`** vivía en `game/city/props/` y lo usan las partículas y `MeshKit`: el 13/11/2026 pasó a `game/common/`.

## El orden que propondría
1. **Los paquetes de ciudad** y lo poco suelto: unas 1.300 líneas, sin decisiones.
2. **Decidir el personaje** (grupo B). De ahí sale si las herramientas de esculpir se quedan.
3. **Decidir el operador de exhibición y los controles**, cuando se diseñen las consolas.
4. **Entallar el núcleo** (grupo A): partir `BoneInstantiator`, limpiar `PlayerController`, renombrar.
Cada paso se verifica igual: que compile todo (`tests/load_all`) y que el sandbox arranque.
