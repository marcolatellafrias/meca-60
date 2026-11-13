class_name CharacterRows
extends RefCounted

## LAS FILAS DEL SANDBOX DE LOS PERSONAJES (ver SandboxRow, docs/sandbox.md): los seis arquetipos y los experimentos de
## locomoción. El afinador de cada arquetipo (F3) está en las dos.

static func rows() -> Array[SandboxRow]:
	return [
		SandboxRow.new(SandboxSuper.Id.CHARACTERS, "Personajes") 			.add(SandboxRow.Build.NEAR, PeopleArchetype.catalogue()) 			.panel(KEY_F3, TUNER, _tuner("Personajes")),
		SandboxRow.new(SandboxSuper.Id.CHARACTERS, "Locomoción") 			.add(SandboxRow.Build.NEAR, LocomotionLabArchetype.catalogue()) 			.panel(KEY_F1, "lo de todos los arquetipos: caerse, llevar, tirar, el aire", LocomotionPanel.new()) 			.panel(KEY_F3, TUNER, _tuner("Locomoción")),
	]


const TUNER := "lo de cada arquetipo: caminata, pose, movimiento, equilibrio, salto, cuerpo"


## El mismo afinador en dos filas necesita otra llave (TunerPanel.ui_copy), o abrir uno abre los dos.
static func _tuner(copy: String) -> LocomotionTuner:
	var tuner := LocomotionTuner.new()
	tuner.ui_copy = copy
	return tuner
