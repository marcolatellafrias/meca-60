class_name BoneShape
extends Resource

## ⚠ SIN USO DESDE EL 18/10/2026: el cuerpo de huesos se borró (ver docs/technical/character-history.md) y esto queda
## sólo porque `character_looks.tres` guarda estos recursos —sin la clase, el archivo no carga—. No lo lee nadie.
##
## UN HUESO DEL CUERPO DE HUESOS, COMO ERA ANTES: sus dos radios, su largo y sus offsets, y nada más —ni el alto de los
## domos ni vueltas intermedias, que son lo que hace del torso un panel de cien perillas—. Lo pidió el dios del juego
## (15/10/2026) para el panel del canónico (F4 en la fila Personajes, ver CharacterLookPanel): la cápsula de cada hueso
## (ver BoneCapsuleMesh) tenía estos números desde el `bone.glb` de marzo, como shape keys.
##
## Los radios y el largo MULTIPLICAN lo que el arquetipo da (×1, el del código): así un arquetipo sigue pudiendo variar
## por individuo y esto lo corre entero. Los offsets son los de la cápsula, en su unidad, y su defecto es el del código
## (ver BoneMeshesUtil.BONE_OFFSETS). El largo es el del HUESO, no sólo el de la malla: de él salen la marcha, el alcance
## y el alto (ver SkeletonSizesUtil.create); los radios y los offsets sólo los dibuja el cuerpo de huesos.
##
## Lo lleva todo el arquetipo, no sólo el canónico (ver CharacterLook.bones), y la izquierda y la derecha son el mismo
## hueso: uno se autora y el otro es su espejo.

@export_range(0.3, 3.0, 0.01, "suffix:×") var radius_top := 1.0
@export_range(0.3, 3.0, 0.01, "suffix:×") var radius_bottom := 1.0
@export_range(0.3, 3.0, 0.01, "suffix:×") var length := 1.0
## LA ALTURA DE CADA DOMO, como múltiplo de la que da el código (lo pidió el dios del juego, 16/10/2026): una punta
## chata o puntiaguda sin tocar el radio.
@export_range(0.1, 3.0, 0.01, "suffix:×") var dome_top := 1.0
@export_range(0.1, 3.0, 0.01, "suffix:×") var dome_bottom := 1.0
## CUÁNTO SE COME CADA PUNTA del largo del hueso, en la unidad de la cápsula (ver BoneCapsuleMesh.OFFSET_GAIN): 0 la
## cúpula termina en la articulación, 1 se mete su radio.
@export_range(-1.0, 2.0, 0.01) var offset_top := 0.0
@export_range(-1.0, 2.0, 0.01) var offset_bottom := 0.0
## CUÁNTO SE CORRE ADELANTE (−) O ATRÁS (+), en medios del radio más chico.
@export_range(-2.0, 2.0, 0.01) var offset_depth := 0.0

func copy() -> BoneShape:
	return duplicate() as BoneShape
