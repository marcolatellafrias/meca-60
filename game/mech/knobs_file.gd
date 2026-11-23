class_name KnobsFile
extends RefCounted

## LAS PERILLAS QUE SE GUARDAN (13/11/2026; el usuario, del F1 de la meca: «no entiendo por qué este panel no tiene
## opción de guardado»; y «fijate si hay otros paneles que les falta guardado»): un recurso de perillas (`current` de
## LegSettings, KinematicSettings, PoseArmSettings) se carga de un `.tres` al arrancar, y su panel F tiene «Guardar» y
## «Volver a lo guardado». Una sola pieza para todos, así se guarda igual en todos lados.
##   · `skip`: perillas que no se guardan ni se vuelven a lo guardado, porque las pone otra cosa. En el archivo quedan las
##     del código. (Hoy no lo usa nadie: cada número tiene un solo dueño.)
##   · LOS ARCHIVOS SON DEL USUARIO: no se suben al repositorio (como el de la forma de la jaula, game/mech/cage/cage_shape.tres).
##   · Los paneles que las muestran son KnobsPanel: borrador, «Guardar» y «Volver a lo guardado».


## Copia de `from` a `into` todas las perillas (las variables del script) menos las de `skip`. UNA PERILLA QUE ES UN
## RECURSO PROPIO (sin archivo, del mismo script: por ejemplo cada poder de un jefe, ver BossPower) se copia ADENTRO,
## no se comparte: así el borrador de un panel no toca lo de verdad hasta guardar (módulo Jefes, 17/11/2026).
static func copy(into: Resource, from: Resource, skip: Array[String] = []) -> void:
	for property in into.get_property_list():
		var name := str(property["name"])
		if not (int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE) or skip.has(name):
			continue
		var theirs: Variant = from.get(name)
		var mine: Variant = into.get(name)
		var own: bool = mine is Resource and theirs is Resource and mine != theirs \
			and (mine as Resource).resource_path.is_empty() and (mine as Resource).get_script() != null
		if own and (mine as Resource).get_script() == (theirs as Resource).get_script():
			KnobsFile.copy(mine, theirs)
		else:
			into.set(name, theirs)


## LO GUARDADO EN `path`, en `fresh` (uno nuevo, con los valores del código): sin archivo, queda como está.
static func load_into(fresh: Resource, path: String, skip: Array[String] = []) -> Resource:
	var stored := load(path) if ResourceLoader.exists(path) else null
	if stored != null and stored.get_script() == fresh.get_script():
		KnobsFile.copy(fresh, stored, skip)
	return fresh


## GUARDA `current` en `path`: una copia nueva (`fresh`, con los valores del código) con todo menos `skip`.
static func save(current: Resource, fresh: Resource, path: String, skip: Array[String] = []) -> Error:
	KnobsFile.copy(fresh, current, skip)
	return ResourceSaver.save(fresh, path)


## LOS DOS BOTONES, SIN BORRADOR (cambian en vivo). *Viejo: lo usa todavía el panel del jefe bola (módulo Jefes). Los
## paneles nuevos usan KnobsPanel, con borrador y un solo camino para aplicar.*
static func buttons(current: Resource, make: Callable, path: String, rebuild: Callable, state: Callable,
		skip: Array[String] = []) -> Array[Button]:
	var save_button := TunerPanel.new_button("Guardar", func() -> void:
		var error := KnobsFile.save(current, make.call(), path, skip)
		state.call("guardado" if error == OK else "no se pudo guardar (%d)" % error))
	var restore := TunerPanel.new_button("Volver a lo guardado", func() -> void:
		KnobsFile.copy(current, KnobsFile.load_into(make.call(), path, skip), skip)
		rebuild.call()
		state.call("volvió a lo guardado"))
	return [save_button, restore]
