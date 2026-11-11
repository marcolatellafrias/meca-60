class_name ShapeLayer

## LO QUE UN RECURSO GUARDADO TIENE DE DISTINTO A SU DEFECTO, como diccionario, y cómo volver a aplicarlo.
##
## Es el mecanismo con el que se guarda lo que el panel del sandbox edita (ver TorsoShapes, PoseShapes): **no se guarda la forma, se guarda la diferencia**.
##
## ── POR QUÉ, Y EL BUG QUE LO OBLIGÓ ─────────────────────────────────────────────────────────────
## Un `.tres` guarda lo que el recurso tenía CUANDO SE GUARDÓ y además NO ESCRIBE lo que vale su defecto de
## clase. Las dos cosas juntas significan que, guardando el objeto entero, lo que se lee después es una
## mezcla silenciosa: los campos que existían vuelven con su valor, y todo lo demás vuelve con el defecto
## DE LA CLASE — que no es el del arquetipo.
##
## Pasó, y por partida doble. La forma del gordo se guardó antes de que el brazo tuviera tabla de vueltas:
##
##   · su `arms` volvía VACÍO, así que el panel no tenía secciones de brazo que mostrar y la pestaña BRAZOS
##     no existía **solo para él** — una perilla que no está no se nota, y la malla se veía bien porque el
##     generador tiene su propio defecto.
##   · y su `leg_length` volvía con 0,9 —el defecto de la CLASE— pisando los 0,942 que su arquetipo dice.
##     O sea que un campo agregado después le cambió las medidas al personaje sin que nadie lo pidiera.
##
## Rellenar los huecos a mano arregla el caso de hoy y no el de mañana: cada campo nuevo vuelve a traerlo,
## y hay que acordarse de agregarlo a la lista de huecos. Guardando la DIFERENCIA no hay lista: lo que el
## archivo no dice no es un dato, así que el defecto del código manda, siempre y para todo campo —incluidos
## los que todavía no existen—.
##
## ── Y LAS PILAS TIENEN EL LARGO QUE DICE EL CÓDIGO ──────────────────────────────────────────────
## Una pila de vueltas lleva una por NOMBRE (cadera, cintura, pecho, hombros…), y los nombres están en el
## código. Así que la capa guarda NÚMEROS POR POSICIÓN y nunca el largo: si mañana el torso tiene cinco
## vueltas, lo guardado con cuatro gana la quinta del arquetipo en vez de quedarse corto.
##
## ── LO VIEJO SE LEE IGUAL ───────────────────────────────────────────────────────────────────────
## Un archivo del formato anterior trae el recurso entero. Se convierte comparándolo contra una instancia
## nueva de su clase, que recupera EXACTAMENTE lo que el archivo decía — porque el archivo ya omitía los
## valores iguales al defecto de clase. No hay migración ni conversión a mano: se lee y queda.

## Las propiedades que CUENTAN son las que un `.tres` guardaría. Deja afuera las virtuales del panel (los
## tildes de permiso) y todo lo que es solo de editor.
const STORED := PROPERTY_USAGE_STORAGE


## LA CAPA: qué tiene `what` de distinto a `base`. Vacía quiere decir "nada que guardar".
static func of(what: Object, base: Object) -> Dictionary:
	var out: Dictionary = {}
	if what == null or base == null:
		return out
	for prop in what.get_property_list():
		if not (int(prop["usage"]) & STORED):
			continue
		var field := str(prop["name"])
		var mine: Variant = what.get(field)
		var theirs: Variant = base.get(field)
		if mine is Array:
			var stack := _stack_of(mine as Array, theirs as Array)
			if not stack.is_empty():
				out[field] = stack
		elif mine is Object:
			# Un recurso anidado suelto: no hay ninguno hoy, y guardarlo entero sería volver al problema.
			continue
		elif not _same(mine, theirs):
			out[field] = mine
	return out


## APLICA UNA CAPA sobre un objeto que ya está completo. Lo que la capa no diga queda como estaba, que es
## toda la gracia.
static func apply(onto: Object, layer: Dictionary) -> void:
	if onto == null:
		return
	for key in layer:
		var field := str(key)
		var value: Variant = layer[key]
		if value is Array:
			_apply_stack(onto.get(field), value as Array)
		else:
			onto.set(field, value)


## UNA PILA, posición por posición. Cada entrada es la capa de esa vuelta; una vacía quiere decir "esta
## vuelta es la del arquetipo". El largo de la pila guardada NO manda: manda el del objeto completo.
static func _stack_of(mine: Array, theirs: Array) -> Array:
	var out: Array = []
	var any := false
	for i in mine.size():
		var item: Object = mine[i] as Object
		if item == null:
			out.append({})
			continue
		var base: Object = theirs[i] as Object if i < theirs.size() else null
		var layer := of(item, base) if base != null else _every(item)
		out.append(layer)
		if not layer.is_empty():
			any = true
	return out if any else []


static func _apply_stack(stack: Variant, layers: Array) -> void:
	if not (stack is Array):
		return
	var list: Array = stack
	for i in mini(list.size(), layers.size()):
		var item: Object = list[i] as Object
		var layer: Variant = layers[i]
		if item != null and layer is Dictionary:
			apply(item, layer as Dictionary)


## Todo lo guardable de un objeto, para cuando no hay con qué compararlo (una vuelta más allá de las que el
## defecto tiene).
static func _every(what: Object) -> Dictionary:
	var out: Dictionary = {}
	for prop in what.get_property_list():
		if not (int(prop["usage"]) & STORED):
			continue
		var value: Variant = what.get(str(prop["name"]))
		if value is Array or value is Object:
			continue
		out[str(prop["name"])] = value
	return out


## Dos valores guardables son el mismo. Los flotantes se comparan con holgura: lo que vuelve de un `.tres`
## pasó por texto, así que 0,002 puede volver como 0,0020000000000000018 — y eso no es una diferencia que
## nadie haya autorado (está en el archivo de hoy, y por eso se mide y no se compara con `==`).
static func _same(a: Variant, b: Variant) -> bool:
	if typeof(a) == TYPE_FLOAT and typeof(b) == TYPE_FLOAT:
		return is_equal_approx(float(a), float(b)) or (is_zero_approx(a) and is_zero_approx(b))
	return a == b


## LO GUARDADO, SEA DEL FORMATO QUE SEA, como capa. Un diccionario ya es una capa; un recurso del formato
## viejo se convierte comparándolo contra una instancia nueva de su clase (ver el encabezado).
static func from_saved(saved: Variant, fresh: Object) -> Dictionary:
	if saved is Dictionary:
		return saved as Dictionary
	if saved is Object:
		return of(saved as Object, fresh)
	return {}
