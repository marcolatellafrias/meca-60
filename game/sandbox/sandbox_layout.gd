class_name SandboxLayout
extends RefCounted

## DÓNDE VA CADA COSA EN EL PISO: las filas declaradas (SandboxRow) pasan a filas de parcelas, con sus pisos y sus
## nombres. Sólo arma; no sabe nada de teclas ni de paneles.
##
## Las filas crecen hacia +Z desde donde uno aparece, y sus parcelas hacia +X. El orden:
##   · por SUPERCATEGORÍA, en el orden de SandboxSuper.Id: cada una es un bloque contiguo con su piso apenas teñido y
##     su nombre a la izquierda;
##   · adentro, las filas en el orden en que se declararon, y AL FINAL DEL BLOQUE una sola fila de ARCHIVADOS (ver
##     SandboxRow.archive), con otro piso, donde cada fila archivada es una subcategoría;
##   · adentro de una fila, sus parcelas en orden; las de una SUBCATEGORÍA, juntas, sobre un piso del tono de su bloque.
##
## LAS CAPAS DEL PISO, de abajo hacia arriba, a milímetros entre sí (a menos se pelean de lejos): el suelo, el de cada
## supercategoría, el de cada subcategoría o de los archivados, y el plano de cada parcela (SandboxParcel.PLANE_LIFT).
## Lo que baja es sólo el dibujo: el colisionador del suelo sigue en 0.

const ELEMENT_GAP := 3.0
const GROUP_GAP := 5.0
const ROW_GAP := 4.0
const SUPER_GAP := 10.0
## Cuánto se extiende el piso de una supercategoría a la izquierda de sus filas, donde va su nombre.
const SUPER_LEFT := 14.0
## Cuánto sale el piso de una subcategoría alrededor de sus zonas de interacción.
const GROUP_MARGIN := 0.6
const GROUND_MARGIN := 300.0
const GROUND_COLOR := Color(0.82, 0.80, 0.76)
const SUPER_SATURATION := 0.1
const GROUP_SATURATION := 0.24
const ARCHIVE_COLOR := Color(0.6, 0.63, 0.7)
const ROW_LABEL_COLOR := Color(0.25, 0.24, 0.22)
const ARCHIVE_NAME := "Archivo"
const GROUND_DRAW_Y := -0.015
const SUPER_FLOOR_Y := -0.01
const GROUP_FLOOR_Y := -0.005


## ARMA TODO colgado de `parent` y devuelve las filas armadas: `{name, archive, parcels: Array[SandboxParcel]}`.
static func build(parent: Node3D, declared: Array[SandboxRow]) -> Array[Dictionary]:
	var built: Array[Dictionary] = []
	var z := 0.0
	var first_super := true
	for super_id: int in SandboxSuper.Id.values():
		var physical := _rows_of(declared, super_id as SandboxSuper.Id)
		if physical.is_empty():
			continue
		if not first_super:
			z += SUPER_GAP
		first_super = false
		var super_start := z
		var super_right := 0.0
		for row in physical:
			var placed := _place_row(parent, row, z)
			built.append(placed)
			z = placed["end_z"]
			super_right = maxf(super_right, placed["end_x"])
			z += ROW_GAP
		var super_end := z - ROW_GAP
		_floor(parent, "Supercategoría " + SandboxSuper.name_of(super_id as SandboxSuper.Id),
			Rect2(-SUPER_LEFT, super_start, super_right + SUPER_LEFT, super_end - super_start),
			Color.from_hsv(SandboxSuper.hue_of(super_id as SandboxSuper.Id), SUPER_SATURATION, GROUND_COLOR.v),
			SUPER_FLOOR_Y)
		_label(parent, SandboxSuper.name_of(super_id as SandboxSuper.Id), 220,
			Vector3(-SUPER_LEFT + 1.5, 0.01, (super_start + super_end) * 0.5), ROW_LABEL_COLOR)
	_ground(parent, built)
	return built


## Las filas de una supercategoría, en el piso: `{name, archive, super_id, entries: [{archetype, build, group, decl}]}`.
static func _rows_of(declared: Array[SandboxRow], super_id: SandboxSuper.Id) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var archive: Array[Dictionary] = []
	for row in declared:
		if row.super_id != super_id:
			continue
		var entries: Array[Dictionary] = []
		for entry in row.parcels:
			var group: String = entry["group"]
			if row.archived:
				group = row.name if group.is_empty() else "%s · %s" % [row.name, group]
			entries.append({"archetype": entry["archetype"], "build": entry["build"], "group": group, "decl": row})
		if row.archived:
			archive.append_array(entries)
		else:
			out.append({"name": row.name, "archive": false, "super_id": super_id, "entries": entries})
	if not archive.is_empty():
		out.append({"name": "%s · %s" % [ARCHIVE_NAME, SandboxSuper.name_of(super_id)], "archive": true,
			"super_id": super_id, "entries": archive})
	return out


## Una fila: sus parcelas a lo largo de X, sus subcategorías y su nombre. Devuelve la fila armada y hasta dónde llegó.
static func _place_row(parent: Node3D, row: Dictionary, z: float) -> Dictionary:
	var entries: Array = row["entries"]
	var depth := 0.0
	var pad := 0.0
	for entry: Dictionary in entries:
		depth = maxf(depth, (entry["archetype"] as SeededArchetype).max_footprint().y)
	for entry: Dictionary in entries:
		var width := (entry["archetype"] as SeededArchetype).max_footprint().x
		pad = maxf(pad, SandboxParcel.pad_for(Vector2(width, depth)))
	var centre_z := z + pad + depth * 0.5
	var parcels: Array[SandboxParcel] = []
	var groups: Array[Dictionary] = []
	var x := 0.0
	var previous_group := ""
	for i in entries.size():
		var entry: Dictionary = entries[i]
		var archetype: SeededArchetype = entry["archetype"]
		var group: String = entry["group"]
		var width := archetype.max_footprint().x
		var own_pad := SandboxParcel.pad_for(Vector2(width, depth))
		if i > 0:
			x += GROUP_GAP if group != previous_group else ELEMENT_GAP
		previous_group = group
		var parcel := SandboxParcel.new()
		parcel.position = Vector3(x + own_pad + width * 0.5, 0.0, centre_z)
		parent.add_child(parcel)
		var decl: SandboxRow = entry["decl"]
		parcel.setup(archetype, decl, group, entry["build"], Vector2(width, depth),
			hash(decl.name + archetype.display_name) & 0x7fffffff)
		parcels.append(parcel)
		if not group.is_empty():
			if groups.is_empty() or groups[-1]["name"] != group:
				groups.append({"name": group, "rect": parcel.interaction_rect()})
			else:
				groups[-1]["rect"] = (groups[-1]["rect"] as Rect2).merge(parcel.interaction_rect())
		x += width + own_pad * 2.0
	# Las hermanas de cada fila declarada: en una de archivados, cada subcategoría es su propia fila.
	for parcel in parcels:
		for other in parcels:
			if other.row == parcel.row:
				parcel.siblings_list.append(other)
	var super_hue := SandboxSuper.hue_of(row["super_id"])
	var archive: bool = row["archive"]
	if archive:
		_floor(parent, "Archivados", Rect2(-1.0, z, x + 1.0, depth + pad * 2.0), ARCHIVE_COLOR, GROUP_FLOOR_Y)
	for group in groups:
		var rect := (group["rect"] as Rect2).grow(GROUP_MARGIN)
		if not archive:
			_floor(parent, "Subcategoría " + str(group["name"]), rect,
				Color.from_hsv(super_hue, GROUP_SATURATION, GROUND_COLOR.v * 0.9), GROUP_FLOOR_Y)
		_label(parent, str(group["name"]), 90, Vector3(rect.get_center().x, 0.012, rect.end.y - 0.5),
			ROW_LABEL_COLOR, 0.0)
	_label(parent, str(row["name"]), 160, Vector3(-1.0, 0.01, centre_z), ROW_LABEL_COLOR)
	return {"name": row["name"], "archive": archive, "parcels": parcels, "end_z": z + depth + pad * 2.0, "end_x": x}


static func _floor(parent: Node3D, floor_name: String, rect: Rect2, color: Color, y: float) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = floor_name
	var plane := PlaneMesh.new()
	plane.size = rect.size
	mesh.mesh = plane
	mesh.material_override = SandboxParcel._flat(color)
	mesh.position = Vector3(rect.get_center().x, y, rect.get_center().y)
	parent.add_child(mesh)


## Un nombre en el piso. `yaw` en grados: −90 se lee a lo largo de la fila (el de la fila y el del bloque), 0 de frente.
static func _label(parent: Node3D, text: String, font_size: int, at: Vector3, color: Color, yaw := -90.0) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.005
	label.modulate = color
	label.outline_size = 0
	label.rotation_degrees = Vector3(-90.0, yaw, 0.0)
	label.position = at
	parent.add_child(label)


## EL SUELO, DEL TAMAÑO DE LAS FILAS: cubre todas las parcelas y `GROUND_MARGIN` alrededor. *Era un cuadrado fijo de
## 900 m y al agregar filas las últimas quedaron afuera (12/11/2026): el cubo, sin piso, salía despedido.* Una fila
## nueva nunca puede quedar fuera del piso.
static func _ground(parent: Node3D, built: Array[Dictionary]) -> void:
	var low := Vector2(-SUPER_LEFT, 0.0)
	var high := Vector2.ZERO
	for row in built:
		for parcel: SandboxParcel in row["parcels"]:
			var rect := parcel.interaction_rect()
			low = low.min(rect.position)
			high = high.max(rect.end)
	low -= Vector2.ONE * GROUND_MARGIN
	high += Vector2.ONE * GROUND_MARGIN
	var extent := high - low
	var centre := (low + high) * 0.5
	var ground := StaticBody3D.new()
	ground.name = "Piso"
	ground.position = Vector3(centre.x, 0.0, centre.y)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = extent
	floor_mesh.mesh = plane
	floor_mesh.material_override = SandboxParcel._flat(GROUND_COLOR)
	floor_mesh.position.y = GROUND_DRAW_Y
	ground.add_child(floor_mesh)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(extent.x, 1.0, extent.y)
	shape.shape = box
	shape.position.y = -0.5
	ground.add_child(shape)
	parent.add_child(ground)
