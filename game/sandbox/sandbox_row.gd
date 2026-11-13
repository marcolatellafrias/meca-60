class_name SandboxRow
extends RefCounted

## UNA FILA DEL SANDBOX, declarada: su supercategoría y su nombre (los dos obligatorios: sin ellos no compila), sus
## parcelas (sueltas o en subcategorías), sus teclas de fila y sus paneles F. Se arma encadenando:
##
##     SandboxRow.new(SandboxSuper.Id.MECH, "Meca discreta") \
##         .add(SandboxRow.Build.NEAR, [MechArchetype.new(Mech.Arms.POSE)]) \
##         .panel(KEY_F1, "la meca: el péndulo…", MechPanel.new())
##
## Cada módulo declara las suyas en un archivo propio (`MechRows.rows()`, `CharacterRows.rows()`…) y SandboxCatalogue
## las junta. Las reglas, en docs/sandbox.md.

## CUÁNDO SE ARMA CADA PARCELA (obligatorio al agregarla):
##   · NEAR    sola, la primera vez que uno se acerca. Es lo normal.
##   · ON_KEY  sólo con la R, parado en ella: lo pesado (una ciudad entera) que no tiene que armarse por pasar al lado.
## En los dos casos, de lejos lo armado se esconde y se pausa, y en su lugar va un cubo gris de su medida.
enum Build { NEAR, ON_KEY }

var super_id: SandboxSuper.Id
var name := ""
## ARCHIVADA (ver `archive`): va con las demás archivadas de su supercategoría, en una sola fila al final del bloque y
## con otro piso, cada una como una subcategoría.
var archived := false
## Sus parcelas, en orden: `{archetype, build, group}` (`group` vacío: suelta).
var parcels: Array[Dictionary] = []
## Las teclas de la fila: valen en todas sus parcelas (`apply(parcel)`; las hermanas, en `parcel.siblings()`).
var keys: Array[SandboxKey] = []
## Sus paneles F: `{key, label, panel, archetype}` (`archetype` null: de toda la fila; si no, sólo de esa parcela).
var panels: Array[Dictionary] = []
## Las opciones que comparten sus arquetipos (SeededArchetype.options): un solo diccionario para toda la fila.
var options: Dictionary = {}


func _init(p_super: SandboxSuper.Id, p_name: String) -> void:
	super_id = p_super
	name = p_name


## Parcelas sueltas, en la fila.
func add(build: Build, archetypes: Array) -> SandboxRow:
	return _add(build, archetypes, "")


## UNA SUBCATEGORÍA: parcelas juntas, con el suelo de otro tono y su nombre.
func group(group_name: String, build: Build, archetypes: Array) -> SandboxRow:
	return _add(build, archetypes, group_name)


func _add(build: Build, archetypes: Array, group_name: String) -> SandboxRow:
	for archetype: SeededArchetype in archetypes:
		for key: Variant in archetype.options:
			if not options.has(key):
				options[key] = archetype.options[key]
		archetype.options = options
		parcels.append({"archetype": archetype, "build": build, "group": group_name})
	return self


## Una tecla de fila (ver SandboxKey).
func key(made: SandboxKey) -> SandboxRow:
	keys.append(made)
	return self


## UN PANEL F DE LA FILA: abre parado en cualquiera de sus parcelas. De F1 a F7 (ver SandboxKey.LOCAL_PANEL_KEYS).
func panel(f_key: Key, label: String, made: TunerPanel) -> SandboxRow:
	panels.append({"key": f_key, "label": label, "panel": made, "archetype": null})
	return self


## UN PANEL F DE UNA PARCELA: abre sólo parado en la de `archetype` (que tiene que ser de esta fila).
func parcel_panel(archetype: SeededArchetype, f_key: Key, label: String, made: TunerPanel) -> SandboxRow:
	panels.append({"key": f_key, "label": label, "panel": made, "archetype": archetype})
	return self


## Que vaya a la fila de archivados de su supercategoría (ver `archived`).
func archive() -> SandboxRow:
	archived = true
	return self
