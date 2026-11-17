class_name CharacterRows
extends RefCounted

## LAS FILAS DEL SANDBOX DE LOS PERSONAJES (ver SandboxRow, docs/technical/sandbox.md): los seis arquetipos y los experimentos de
## locomoción, con las formas de cabeza al final (HeadFormsArchetype). Los dos paneles —lo de todos (F1) y lo de cada arquetipo (F3)— están en las dos.

static func rows() -> Array[SandboxRow]:
	return [
		SandboxRow.new(SandboxSuper.Id.CHARACTERS, "Personajes") 			.add(SandboxRow.Build.NEAR, PeopleArchetype.catalogue()) 			.panel(KEY_F1, COMMON, _common("Personajes")) 			.panel(KEY_F3, TUNER, _tuner("Personajes")),
		SandboxRow.new(SandboxSuper.Id.CHARACTERS, "Locomoción") 			.add(SandboxRow.Build.NEAR, LocomotionLabArchetype.catalogue()) 			.add(SandboxRow.Build.NEAR, HeadFormsArchetype.catalogue()) 			.panel(KEY_F1, COMMON, _common("Locomoción")) 			.panel(KEY_F3, TUNER, _tuner("Locomoción")),
	]


const TUNER := "lo de cada arquetipo: caminata, pose, movimiento, equilibrio, salto, cuerpo"
const COMMON := "lo de todos los arquetipos: caerse, llevar, tirar, el aire"


static func _common(copy: String) -> LocomotionPanel:
	var panel := LocomotionPanel.new()
	panel.ui_copy = copy
	return panel


## El mismo afinador en dos filas necesita otra llave (TunerPanel.ui_copy), o abrir uno abre los dos.
static func _tuner(copy: String) -> LocomotionTuner:
	var tuner := LocomotionTuner.new()
	tuner.ui_copy = copy
	return tuner
