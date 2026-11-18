class_name CharacterRows
extends RefCounted

## LAS FILAS DEL SANDBOX DE LOS PERSONAJES (ver SandboxRow, docs/technical/sandbox.md): los seis arquetipos y los experimentos de
## locomoción; y las formas de cabeza, con su editor (HeadFormsArchetype, HeadFormsPanel). El panel de locomoción (F3: lo de cada arquetipo y lo de todos) está en las dos.

static func rows() -> Array[SandboxRow]:
	return [
		SandboxRow.new(SandboxSuper.Id.CHARACTERS, "Personajes") 			.add(SandboxRow.Build.NEAR, PeopleArchetype.catalogue()) 			.panel(KEY_F3, TUNER, _tuner("Personajes")),
		SandboxRow.new(SandboxSuper.Id.CHARACTERS, "Cabezas") 			.add(SandboxRow.Build.NEAR, HeadFormsArchetype.catalogue()) 			.add(SandboxRow.Build.NEAR, HeadPaintArchetype.catalogue()) 			.panel(KEY_F3, "las formas de cabeza: editar, agregar, el aplanamiento de todas", HeadFormsPanel.new()) 			.panel(KEY_F1, "pintar con píxeles la cara que mirás", _painter()),
		SandboxRow.new(SandboxSuper.Id.CHARACTERS, "Locomoción") 			.add(SandboxRow.Build.NEAR, LocomotionLabArchetype.catalogue()) 			.panel(KEY_F3, TUNER, _tuner("Locomoción")),
	]


const TUNER := "locomoción: lo de cada arquetipo y lo de todos (caminata, pose, movimiento, equilibrio, salto, cuerpo)"


## EL PANEL DE PINTAR DE LA FILA PÍXELES, también acá (ver HeadPaintArchetype), con su propia llave.
static func _painter() -> PixelPaintPanel:
	var panel := PixelPaintPanel.new()
	panel.ui_copy = "Cabezas"
	return panel


## El mismo afinador en dos filas necesita otra llave (TunerPanel.ui_copy), o abrir uno abre los dos.
static func _tuner(copy: String) -> LocomotionTuner:
	var tuner := LocomotionTuner.new()
	tuner.ui_copy = copy
	return tuner
