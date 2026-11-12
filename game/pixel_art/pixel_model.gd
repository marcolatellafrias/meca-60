class_name PixelModel
extends Node3D

## UN MODELO PINTADO CON PÍXELES, cara por cara (ver docs/pixel-art.md). Toma triángulos —de un `.glb` traído de Blender
## (`from_scene`) o de una malla armada en código (`from_mesh`, el cubo de 63 cm)—, detecta sus caras rectas
## (PixelFaces), les da un rectángulo a cada una en un atlas y se dibuja con esa textura, en píxeles duros.
##
## LA MEMORIA (lo pidió el usuario, 13/11/2026: «si cambio algún detallito de un modelo… no quiero volver a hacer todas
## las texturas»): LO PINTADO NO SE GUARDA POR CARA NI POR ATLAS, sino POR PÍXEL ANCLADO AL MODELO: la clave de un píxel
## es la dirección de su cara y la posición de su centro (ver `anchor`). Al remodelar, las caras se vuelven a detectar y
## cada píxel busca su clave: una cara que no cambió conserva todo; una que se agrandó, lo que se superpone; una que se
## corrió, nada. Y lo que ya no existe NO SE BORRA del archivo: vuelve si se vuelve a la versión anterior. El atlas se
## rearma cada vez; no importa en qué orden caigan las caras.
##
## LAS COSTURAS: el filtro es «más cercano» y sin mipmaps (un píxel nunca se mezcla con el de al lado), y cada rectángulo
## del atlas tiene un borde de un píxel que repite su orilla (un error de redondeo en la arista no toma el color de otra
## cara). Que el dibujo de una cara siga en la vecina sin saltos depende de MODELAR SOBRE LA GRILLA: medidas enteras de
## píxeles. Lo inclinado (un chanfle) queda con su grilla aparte.
##
## SE GUARDA en `painted/<nombre>.json`: {clave: "rrggbb"} más la densidad. Sólo desde el sandbox (escribe en res://).

## LA DENSIDAD: píxeles por cada cubo de 63 cm (16 → un píxel de 3,9 cm, unos 25 por metro). Una para todo el juego;
## `pixels_per_cell` la cambia sólo para comparar (el test de las resoluciones).
const PIXELS_PER_CELL := 16
const CELL := 0.63
const FOLDER := "res://game/pixel_art/painted/"

## El nombre del archivo de su pintura. Dos versiones de un modelo con el mismo nombre comparten pintura.
var paint_name := ""
var pixels_per_cell := PIXELS_PER_CELL
var pixel := CELL / PIXELS_PER_CELL
## Dónde se guarda (el test usa user://, para no escribir en el repo). Se escribe antes de `from_scene`/`from_mesh`.
var folder := FOLDER
var faces: Array[PixelFace] = []
## Lo pintado: clave del píxel (ver `anchor`) → color. Incluye lo que el modelo de ahora ya no tiene.
var painted: Dictionary = {}
var atlas: Image = null
var atlas_side := 32
var _texture: ImageTexture = null
var _mesh_instance: MeshInstance3D = null


## Un modelo de Blender: junta los triángulos de todas sus mallas, con su color de material.
func from_scene(scene: PackedScene, name_for_paint: String) -> PixelModel:
	var holder := scene.instantiate() as Node3D
	var triangles := PackedVector3Array()
	var colors := PackedColorArray()
	for part: MeshInstance3D in holder.find_children("*", "MeshInstance3D", true, false):
		var place := _place_in(part, holder)
		for surface in part.mesh.get_surface_count():
			var material := part.get_active_material(surface) as BaseMaterial3D
			_collect(part.mesh, surface, place, material.albedo_color if material != null else Color.WHITE,
				triangles, colors)
	holder.free()
	return _setup(triangles, colors, name_for_paint)


## Una malla armada en código, de un color.
func from_mesh(mesh: Mesh, color: Color, name_for_paint: String) -> PixelModel:
	var triangles := PackedVector3Array()
	var colors := PackedColorArray()
	for surface in mesh.get_surface_count():
		_collect(mesh, surface, Transform3D.IDENTITY, color, triangles, colors)
	return _setup(triangles, colors, name_for_paint)


## LA CLAVE DE UN PÍXEL: la dirección de su cara (centésimas) y su centro (en medios píxeles), los dos en el espacio del
## modelo. No depende del orden de las caras ni del atlas: por eso sobrevive a remodelar.
func anchor(face: PixelFace, x: int, y: int) -> String:
	var direction := Vector3i((face.normal * 100.0).round())
	var at := Vector3i((face.centre(x, y, pixel) / pixel * 2.0).round())
	return "%d,%d,%d|%d,%d,%d" % [direction.x, direction.y, direction.z, at.x, at.y, at.z]


## El color que se ve en un píxel: lo pintado o, si no, el del material.
func color_at(face: PixelFace, x: int, y: int) -> Color:
	var key := anchor(face, x, y)
	return painted[key] if painted.has(key) else face.base[y * face.width + x]


## Pinta un píxel (`erase`: vuelve al color del material). No guarda: ver `save`.
func paint(face: PixelFace, x: int, y: int, color: Color, erase := false) -> void:
	if not face.inside(x, y):
		return
	var key := anchor(face, x, y)
	if erase:
		painted.erase(key)
	else:
		painted[key] = color
	_write_pixel(face, x, y)


## Lo vuelve a dibujar después de pintar (una vez por trazo, no por píxel).
func refresh() -> void:
	_texture.update(atlas)


## CUÁNTO DE LO GUARDADO ENCONTRÓ LUGAR en el modelo de ahora (para ver qué sobrevivió a un cambio).
func matched() -> Vector2i:
	var used := 0
	for face in faces:
		for y in face.height:
			for x in face.width:
				if face.inside(x, y) and painted.has(anchor(face, x, y)):
					used += 1
	return Vector2i(used, painted.size())


## La cara y el píxel que toca un rayo (en el mundo), o {} si no toca nada.
func pick(from: Vector3, direction: Vector3) -> Dictionary:
	var inverse := global_transform.affine_inverse()
	var local_from := inverse * from
	var local_dir := (inverse.basis * direction).normalized()
	var best := INF
	var out := {}
	for face in faces:
		if face.normal.dot(local_dir) >= 0.0:
			continue
		for index in range(0, face.triangles.size(), 3):
			var hit: Variant = Geometry3D.ray_intersects_triangle(local_from, local_dir, face.triangles[index],
				face.triangles[index + 1], face.triangles[index + 2])
			if hit != null and (hit as Vector3).distance_to(local_from) < best:
				best = (hit as Vector3).distance_to(local_from)
				var spot := face.local(hit as Vector3, pixel)
				out = {"face": face, "x": clampi(floori(spot.x), 0, face.width - 1),
					"y": clampi(floori(spot.y), 0, face.height - 1)}
	return out


func save() -> void:
	var data := {"pixels_per_cell": pixels_per_cell, "pixels": {}}
	var keys := painted.keys()
	keys.sort()
	for key: String in keys:
		data["pixels"][key] = (painted[key] as Color).to_html(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var file := FileAccess.open(folder + paint_name + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))


func load_paint() -> void:
	painted.clear()
	var path := folder + paint_name + ".json"
	if not FileAccess.file_exists(path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary):
		return
	var pixels: Dictionary = (data as Dictionary).get("pixels", {})
	for key: String in pixels:
		painted[key] = Color.html(str(pixels[key]))


## Borra lo pintado de este modelo, también del archivo.
func clear_paint() -> void:
	painted.clear()
	_redraw()
	save()


## ── EL ARMADO ──────────────────────────────────────────────────────────────────────────────────────────────────────

func _setup(triangles: PackedVector3Array, colors: PackedColorArray, name_for_paint: String) -> PixelModel:
	paint_name = name_for_paint
	pixel = CELL / pixels_per_cell
	faces = PixelFaces.detect(triangles, colors, pixel)
	atlas_side = PixelFaces.pack(faces)
	load_paint()
	atlas = Image.create(atlas_side, atlas_side, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(1, 0, 1))
	_texture = ImageTexture.create_from_image(atlas)
	_redraw()
	_build_mesh()
	return self


func _redraw() -> void:
	for face in faces:
		for y in face.height:
			for x in face.width:
				_write_pixel(face, x, y)
	if _texture != null:
		_texture.update(atlas)


## Escribe un píxel en el atlas y, si está en la orilla de su rectángulo, también el borde de afuera (ver LAS COSTURAS).
## Un píxel que la cara no toca toma el color de su vecino tocado más cercano, por si un redondeo lo alcanza.
func _write_pixel(face: PixelFace, x: int, y: int) -> void:
	var color := color_at(face, x, y) if face.inside(x, y) else _nearest_inside(face, x, y)
	var spot := face.at + Vector2i(x, y)
	atlas.set_pixelv(spot, color)
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var nx: int = x + dx
			var ny: int = y + dy
			if nx < 0 or ny < 0 or nx >= face.width or ny >= face.height:
				atlas.set_pixelv(face.at + Vector2i(nx, ny), color)
			elif face.inside(x, y) and not face.inside(nx, ny):
				atlas.set_pixelv(face.at + Vector2i(nx, ny), color)


func _nearest_inside(face: PixelFace, x: int, y: int) -> Color:
	for reach in range(1, 4):
		for dx in range(-reach, reach + 1):
			for dy in range(-reach, reach + 1):
				if face.inside(x + dx, y + dy):
					return color_at(face, x + dx, y + dy)
	return face.base[y * face.width + x]


func _build_mesh() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in faces:
		for point in face.triangles:
			tool.set_normal(face.normal)
			tool.set_uv((Vector2(face.at) + face.local(point, pixel)) / atlas_side)
			tool.add_vertex(point)
	var material := StandardMaterial3D.new()
	material.albedo_texture = _texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 0.85
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "Pintado"
	_mesh_instance.mesh = tool.commit()
	_mesh_instance.material_override = material
	add_child(_mesh_instance)


## La transformación de una malla dentro de la escena importada.
static func _place_in(part: Node3D, root: Node3D) -> Transform3D:
	var place := Transform3D.IDENTITY
	var node: Node = part
	while node != root and node is Node3D:
		place = (node as Node3D).transform * place
		node = node.get_parent()
	return place


## Los triángulos de una superficie (con `surface_get_arrays`: `get_faces` redondea las posiciones), con el frente
## orientado según sus normales.
static func _collect(mesh: Mesh, surface: int, place: Transform3D, color: Color, triangles: PackedVector3Array,
		colors: PackedColorArray) -> void:
	var arrays := mesh.surface_get_arrays(surface)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if indices.is_empty():
		indices.resize(points.size())
		for i in points.size():
			indices[i] = i
	for tri in range(0, indices.size() - 2, 3):
		var a := place * points[indices[tri]]
		var b := place * points[indices[tri + 1]]
		var c := place * points[indices[tri + 2]]
		var given := place.basis * (normals[indices[tri]] + normals[indices[tri + 1]] + normals[indices[tri + 2]])
		# El orden que da la normal de PixelFaces; si contradice a la de la malla, se dan vuelta.
		if (c - a).cross(b - a).dot(given) < 0.0:
			var swap := b
			b = c
			c = swap
		triangles.append_array(PackedVector3Array([a, b, c]))
		colors.append(color)
