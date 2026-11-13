class_name KnobsFile
extends RefCounted

## LAS PERILLAS QUE SE GUARDAN (13/11/2026; el usuario, del F1 de la meca: «no entiendo por qué este panel no tiene
## opción de guardado»; y «fijate si hay otros paneles que les falta guardado»): un recurso de perillas (`current` de
## BodySettings, PillarSettings, MuscleArmSettings) se carga de un `.tres` al arrancar, y su panel F tiene «Guardar» y
## «Volver a lo guardado». Una sola pieza para todos, así se guarda igual en todos lados.
##   · `skip`: perillas que no se guardan ni se vuelven a lo guardado, porque las pone otra cosa (las del F1 de la meca
##     que salen de la forma del F2: ver BodySettings.FROM_BODY). En el archivo quedan las del código.
##   · LOS ARCHIVOS SON DEL USUARIO: no se suben al repositorio (como el de la forma, game/consoles/cabin_shape.tres).
##   · `buttons` arma los dos botones para el panel, con `state` (una línea del panel) para decir qué pasó.


## Copia de `from` a `into` todas las perillas (las variables del script) menos las de `skip`.
static func copy(into: Resource, from: Resource, skip: Array[String] = []) -> void:
	for property in into.get_property_list():
		var name := str(property["name"])
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE and not skip.has(name):
			into.set(name, from.get(name))


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


## LOS DOS BOTONES para un panel F: «Guardar» y «Volver a lo guardado». `make` hace uno nuevo con los valores del
## código (`func(): return X.new()`), `rebuild` rearma el panel y `state` es la línea donde avisan.
static func buttons(current: Resource, make: Callable, path: String, rebuild: Callable, state: Callable,
		skip: Array[String] = []) -> Array[Button]:
	var save := TunerPanel.new_button("Guardar", func() -> void:
		var error := KnobsFile.save(current, make.call(), path, skip)
		var said := "guardado" if error == OK else "no se pudo guardar (%d)" % error
		state.call(said + (" (menos lo que sale de otro lado)" if not skip.is_empty() else "")))
	var restore := TunerPanel.new_button("Volver a lo guardado", func() -> void:
		KnobsFile.copy(current, KnobsFile.load_into(make.call(), path, skip), skip)
		rebuild.call()
		state.call("volvió a lo guardado"))
	return [save, restore]
