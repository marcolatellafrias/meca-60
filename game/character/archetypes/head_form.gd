class_name HeadForm
extends Resource

## LA FORMA DE UNA CABEZA, DE NUEVO: un cilindro con un domo en cada punta, como la malla de `bone.glb` con la que se
## dibujaban los huesos en la build de marzo (después BoneCapsuleMesh, borrada el 18/10/2026), y unos pocos loop cuts entre las dos tapas. Lo pidió
## el dios del juego (13/10/2026): la pila de vueltas de HeadShape nació para poder hacer cabezas cuadradas y otras
## redondas, y como ya no va a haber cuadradas, daba una geometría fea —tramos rectos entre vueltas, esquinas de
## superelipse— para conseguir curvas. Acá todo es curvo de entrada:
##
##   · LAS SECCIONES SON CÍRCULOS, siempre: un diámetro por anillo, que sólo crece o se achica y se corre adelante o
##     atrás —nunca se deforma—. Lo único que rompe el círculo es la cara aplanada (ver `ring_point`), y es una para
##     todas las cabezas (ver HeadForms.face_flat). Lo pidió el dios del juego (16/10/2026): el pelo se va a modelar
##     sobre algo estándar —el círculo de la tapa de arriba y uno más abajo, que dan un tamaño y una inclinación—, y con
##     elipses cada cabeza era otra cosa. Antes cada anillo tenía ancho y fondo; quedó el ancho.
##   · LAS DOS TAPAS mandan siempre —su diámetro, cuánto se corren hacia adelante y lo alto de su domo— y son lo
##     que el pelo va a poder leer sin adivinar (la de arriba es donde apoya).
##   · LOS LOOP CUTS DEL MEDIO se prenden de a uno (ver HeadCut): la forma pasa por los que mandan con una curva suave
##     —una cúbica monótona por canal, que no se pasa de largo entre dos cortes— y por los apagados, interpolada.
##
## Es la primera parte del plan del dios del juego: hacer acá unas cuantas formas que le gusten; después, ver en
## cuántos cortes se descomponen y modelar el pelo sobre eso (quizás exportando la forma a Blender, con los cortes como
## blend shapes). Es LA cabeza del personaje desde el 15/10/2026 (la pila de vueltas se borró): cada arquetipo canónico
## elige una forma (ver CharacterLook.head_form), y se edita en la fila «Formas de cabeza» (ver HeadFormArchetype).

## Los cortes de plantilla y dónde caen por defecto.
const CUTS := 7
## LA MALLA, LOW POLY (13/11/2026, el usuario: «cuando veía… no se veían low poly, se veían como high poly… los edge
## loops discretos»): ocho lados alrededor, dos anillos en cada domo, y A LO LARGO SÓLO LOS ANILLOS QUE MANDAN —las dos
## tapas y los cortes prendidos—: cada loop cut es una arista que se ve, y nada se interpola entre ellos. Las caras iban
## planas. *Antes la malla pasaba por una curva suave de 24 anillos (o 4 parejos en el «low poly»), así que los cortes
## no eran aristas sino una curva, y las normales suaves la redondeaban más.* Desde el 13/11/2026 (después) el
## sombreado es suave otra vez, sobre esas mismas pocas caras (ver `build_arrays`).
const AROUND := 8
const DOME_RINGS := 2

@export var name := ""
## EL ALTO DEL CILINDRO, entre las dos tapas, en metros. Los domos suman arriba y abajo.
@export_range(0.02, 0.4, 0.001, "suffix:m") var height := 0.12
## ── EL FRENTE PLANO ─────────────────────────────────────────────────────────────────────────────
## Prendido, EL FRENTE DE LA CARA ES UNA VERTICAL: cada anillo del cilindro —las dos tapas, los cortes y todo lo de
## entre medio— se corre lo justo para que su punto de adelante caiga sobre la línea del frente de la tapa de abajo. Lo
## que cambia el ancho y el fondo crece hacia los costados y hacia atrás, nunca hacia la cara. Lo pidió el dios del
## juego (13/10/2026): los pómulos alineados son esto, con la tapa de abajo, el corte del medio y la de arriba a plomo.
## Los «adelante» de las tapas y de los cortes no cuentan mientras esté prendido; el de la tapa de abajo, sí: es dónde
## está la línea.
@export var flat_front := false
## ── LA CARA APLANADA ────────────────────────────────────────────────────────────────────────────
## Cuánto se aplana ADELANTE cada anillo, de 0 —el círculo— a 1 —el frente casi recto de lado a lado—: los rasgos van
## pintados en un paño al frente (ver FacePlane), y como en los Mii o en Animal Crossing se leen mejor sobre una cara
## plana. Atrás y a los costados el anillo sigue siendo el círculo, y el punto de adelante no se mueve (ver
## `ring_point`). Es el horizontal de `flat_front`, que es el vertical.
##
## ES UNA PARA TODAS LAS CABEZAS (ver HeadForms.face_flat, lo pidió el dios del juego, 16/10/2026): no se guarda con la
## forma. Esto, en −1, la toma de ahí; sólo una captura que compara grados la fija para una forma.
var face_flat := -1.0

@export_group("Tapa de abajo")
## EL DIÁMETRO DE LA TAPA DE ABAJO.
@export_range(0.03, 0.4, 0.001, "suffix:m") var bottom_width := 0.15
@export_range(-0.08, 0.08, 0.001, "suffix:m") var bottom_forward := 0.0
@export_range(0.0, 0.2, 0.001, "suffix:m") var bottom_dome := 0.05

@export_group("Tapa de arriba")
## EL DIÁMETRO DE LA TAPA DE ARRIBA.
@export_range(0.03, 0.4, 0.001, "suffix:m") var top_width := 0.16
@export_range(-0.08, 0.08, 0.001, "suffix:m") var top_forward := 0.0
@export_range(0.0, 0.2, 0.001, "suffix:m") var top_dome := 0.07

@export_group("")
@export var cuts: Array[HeadCut] = []


## Una forma con sus siete cortes en su lugar de siempre, apagados, del tamaño de las tapas interpoladas.
static func make(new_name: String) -> HeadForm:
	var out := HeadForm.new()
	out.name = new_name
	out.ensure_cuts()
	return out


## LOS CORTES DE PLANTILLA: si faltan, se agregan en su lugar de siempre y apagados, con lo que la forma ya pasa por
## ahí —así prender uno no cambia nada hasta que se lo mueve—.
func ensure_cuts() -> void:
	while cuts.size() < CUTS:
		var cut := HeadCut.new()
		cut.at = float(cuts.size() + 1) / float(CUTS + 1)
		var here := section(cut.at)
		cut.width = here.x
		cut.forward = here.z
		cuts.append(cut)


## LO GUARDADO DE ANTES que ya no existe se acepta y se ignora: la cara (la boca, los ojos, las orejas) y el atlas,
## sacados el 13/11/2026.
func _set(property: StringName, _value: Variant) -> bool:
	return property in [&"mouth_drop", &"mouth_width", &"eye_apart", &"eye_size", &"atlas", &"ear_model", &"ear_height",
		&"ear_back", &"ear_size", &"ear_out"]


func copy() -> HeadForm:
	var out := HeadForm.new()
	for property in ["name", "height", "flat_front", "face_flat", "bottom_width", "bottom_forward", "bottom_dome", "top_width",
			"top_forward", "top_dome"]:
		out.set(property, get(property))
	for cut in cuts:
		out.cuts.append(cut.copy())
	return out


## Lo alto de la cabeza entera, del fondo del domo de abajo a la punta del de arriba.
func total_height() -> float:
	return bottom_dome + height + top_dome


## LA MISMA FORMA MÁS GRANDE O MÁS CHICA: todos sus metros por `factor` (el `at` de los cortes y la cara aplanada son
## fracciones y no se tocan). Lo piden la escala de cabeza del cuerpo y la lupa del sandbox (ver SkeletonSizesUtil).
func scaled(factor: float) -> HeadForm:
	var out := copy()
	if is_equal_approx(factor, 1.0):
		return out
	for property in ["height", "bottom_width", "bottom_forward", "bottom_dome", "top_width", "top_forward", "top_dome"]:
		out.set(property, float(get(property)) * factor)
	for cut in out.cuts:
		cut.width *= factor
		cut.forward *= factor
	return out


## ── LA SECCIÓN A LO LARGO DEL CILINDRO ─────────────────────────────────────────────────────────
## `(ancho, fondo, adelante)` en la fracción `t` del cilindro —el ancho y el fondo, el mismo diámetro: el anillo es un
## círculo— (0 la tapa de abajo, 1 la de arriba). Pasa por las tapas
## y por los cortes que mandan con una cúbica de Hermite MONÓTONA por canal (Fritsch–Carlson): suave, y sin pasarse de
## largo entre dos cortes, que es lo que haría un spline común y se vería como un bulto que nadie puso.
func section(t: float) -> Vector3:
	var ts := PackedFloat32Array([0.0])
	var values: Array[Vector3] = [Vector3(bottom_width, bottom_width, bottom_forward)]
	var sorted := cuts.filter(func(c: HeadCut) -> bool: return c.active)
	sorted.sort_custom(func(a: HeadCut, b: HeadCut) -> bool: return a.at < b.at)
	for cut: HeadCut in sorted:
		if cut.at > ts[ts.size() - 1] + 0.01 and cut.at < 0.99:
			ts.append(cut.at)
			values.append(Vector3(cut.width, cut.width, cut.forward))
	ts.append(1.0)
	values.append(Vector3(top_width, top_width, top_forward))
	var out := Vector3.ZERO
	for axis in [0, 2]:
		var ys := PackedFloat32Array()
		for v in values:
			ys.append(v[axis])
		out[axis] = _monotone(ts, ys, clampf(t, 0.0, 1.0))
	out.y = out.x
	# EL FRENTE PLANO: el corrimiento sale del fondo, para que el frente quede siempre en la misma línea.
	if flat_front:
		out.z = bottom_width * 0.5 + bottom_forward - out.y * 0.5
	return out


## LA SECCIÓN A UNA ALTURA CUALQUIERA, en metros desde el fondo del domo de abajo: en los domos el anillo se achica como
## una elipse. Es lo que va a leer quien le apoye cosas (el pelo, los rasgos).
func section_at_height(y: float) -> Vector3:
	var body_y := y - bottom_dome
	if body_y < 0.0:
		var end := section(0.0)
		var s := _dome_scale(-body_y, bottom_dome)
		return Vector3(end.x * s, end.y * s, end.z)
	if body_y > height:
		var end := section(1.0)
		var s := _dome_scale(body_y - height, top_dome)
		return Vector3(end.x * s, end.y * s, end.z)
	return section(body_y / maxf(height, 1e-5))


static func _dome_scale(into: float, dome: float) -> float:
	if dome <= 1e-5:
		return 0.0
	var k := clampf(into / dome, 0.0, 1.0)
	return sqrt(maxf(1.0 - k * k, 0.0))


static func _monotone(xs: PackedFloat32Array, ys: PackedFloat32Array, x: float) -> float:
	var n := xs.size()
	if n == 1:
		return ys[0]
	var slopes := PackedFloat32Array()
	for i in n - 1:
		slopes.append((ys[i + 1] - ys[i]) / maxf(xs[i + 1] - xs[i], 1e-6))
	var tangents := PackedFloat32Array()
	tangents.resize(n)
	tangents[0] = slopes[0]
	tangents[n - 1] = slopes[n - 2]
	for i in range(1, n - 1):
		tangents[i] = 0.0 if slopes[i - 1] * slopes[i] <= 0.0 else (slopes[i - 1] + slopes[i]) * 0.5
	for i in n - 1:
		if absf(slopes[i]) < 1e-9:
			tangents[i] = 0.0
			tangents[i + 1] = 0.0
			continue
		var a := tangents[i] / slopes[i]
		var b := tangents[i + 1] / slopes[i]
		var r := a * a + b * b
		if r > 9.0:
			var k := 3.0 / sqrt(r)
			tangents[i] = k * a * slopes[i]
			tangents[i + 1] = k * b * slopes[i]
	var seg := 0
	while seg < n - 2 and x > xs[seg + 1]:
		seg += 1
	var h := maxf(xs[seg + 1] - xs[seg], 1e-6)
	var s := (x - xs[seg]) / h
	var s2 := s * s
	var s3 := s2 * s
	return (2.0 * s3 - 3.0 * s2 + 1.0) * ys[seg] + (s3 - 2.0 * s2 + s) * h * tangents[seg] \
		+ (-2.0 * s3 + 3.0 * s2) * ys[seg + 1] + (s3 - s2) * h * tangents[seg + 1]


## ── LA MALLA ────────────────────────────────────────────────────────────�
## Del fondo del domo de abajo (y = 0) a la punta del de arriba, con el frente hacia −Z como todo el proyecto, low poly
## (ver AROUND): los anillos son los de los domos, las dos tapas y los cortes prendidos, y nada más. EL SOMBREADO ES
## SUAVE: vértices compartidos con la normal promediada. El bobinado se decide midiendo: si las caras quedaron mirando para adentro, se dan vuelta
## (ver la nota del proyecto sobre el frente horario de Godot).
func build_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, build_arrays())
	return mesh


## Las alturas de sus anillos, del fondo del domo de abajo (sin los dos polos): los de los domos, las dos tapas y los
## cortes prendidos.
func ring_heights() -> Array[float]:
	var rows: Array[float] = []
	for k in range(1, DOME_RINGS):
		rows.append(bottom_dome * (1.0 - sin(PI * 0.5 * (1.0 - float(k) / DOME_RINGS))))
	rows.append(bottom_dome)
	var on := cuts.filter(func(c: HeadCut) -> bool: return c.active and c.at > 0.01 and c.at < 0.99)
	on.sort_custom(func(a: HeadCut, b: HeadCut) -> bool: return a.at < b.at)
	for cut: HeadCut in on:
		rows.append(bottom_dome + cut.at * height)
	rows.append(bottom_dome + height)
	for k in range(1, DOME_RINGS):
		rows.append(bottom_dome + height + top_dome * sin(PI * 0.5 * float(k) / DOME_RINGS))
	return rows


func build_arrays() -> Array:
	var verts := PackedVector3Array()
	verts.append(Vector3(0.0, 0.0, -section(0.0).z))
	var rows := ring_heights()
	for y in rows:
		var s := section_at_height(y)
		for j in AROUND:
			verts.append(ring_point(s.x, s.y, s.z, TAU * float(j) / float(AROUND), y))
	verts.append(Vector3(0.0, total_height(), -section(1.0).z))
	var last_pole := verts.size() - 1
	var tris := PackedInt32Array()
	for j in AROUND:
		var j1 := (j + 1) % AROUND
		# LAS PUNTAS, CON EL MISMO GIRO QUE LOS TRAMOS: al revés, la medida de abajo las daba vuelta y quedaban de
		# espaldas, un agujero en cada punta (lo vio el dios del juego, 16/10/2026).
		tris.append_array([0, 1 + j1, 1 + j])
		var top := 1 + (rows.size() - 1) * AROUND
		tris.append_array([last_pole, top + j, top + j1])
	for r in rows.size() - 1:
		for j in AROUND:
			var j1 := (j + 1) % AROUND
			var a := 1 + r * AROUND + j
			var b := 1 + r * AROUND + j1
			tris.append_array([a, b, b + AROUND, a, b + AROUND, a + AROUND])
	# EL BOBINADO, MEDIDO: la normal de cada cara contra la dirección hacia afuera del eje.
	var outward := 0.0
	for i in range(0, tris.size(), 3):
		var p0 := verts[tris[i]]
		var n := (verts[tris[i + 1]] - p0).cross(verts[tris[i + 2]] - p0)
		outward += n.dot(Vector3(p0.x, 0.0, p0.z))
	var flip := outward > 0.0
	# EL SOMBREADO SUAVE (13/11/2026, el usuario: «sombreado suave, nada más eso»): las mismas pocas caras, pero los
	# vértices compartidos y cada normal el promedio de las caras que lo tocan (pesado por su área), así la luz pasa
	# redondeada por las aristas. Con el frente horario de Godot, la normal hacia afuera es la cuenta al revés.
	var order := PackedInt32Array()
	var normals := PackedVector3Array()
	normals.resize(verts.size())
	for i in range(0, tris.size(), 3):
		var ia := tris[i]
		var ib := tris[i + 2 if flip else i + 1]
		var ic := tris[i + 1 if flip else i + 2]
		var n := (verts[ic] - verts[ia]).cross(verts[ib] - verts[ia])
		for k in [ia, ib, ic]:
			normals[k] += n
		order.append_array(PackedInt32Array([ia, ib, ic]))
	for i in normals.size():
		normals[i] = normals[i].normalized()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = order
	return arrays


## UN PUNTO DEL ANILLO a `angle` radianes desde el frente (−Z) hacia +X, de ancho `width`, fondo `depth` y corrido
## `forward` hacia adelante, a la altura `y`. Atrás y a los costados, la elipse. Adelante, con la cara aplanada, cada
## punto se EMPUJA HACIA EL PLANO DE LA CARA —el del punto de adelante, que no se mueve— tanto más cuanto más al frente
## está, sin correrse de lado: así los vértices quedan repartidos igual que en la elipse. *Una superelipse los juntaba
## en los costados y dejaba el frente en una sola cara grande, que se veía como una arista por el medio.*
func ring_point(width: float, depth: float, forward: float, angle: float, y: float) -> Vector3:
	var s := sin(angle)
	var c := cos(angle)
	var front := c
	var flat := face_flat if face_flat >= 0.0 else HeadForms.face_flat_all()
	if flat > 0.0 and c > 0.0:
		front = lerpf(c, 1.0, flat * sqrt(c))
	return Vector3(s * width * 0.5, y, -front * depth * 0.5 - forward)


## Una línea para el panel.
func describe() -> String:
	var on := 0
	for cut in cuts:
		if cut.active:
			on += 1
	return "alto %.3f m (cilindro %.3f) · abajo ⌀ %.3f · arriba ⌀ %.3f · %d cortes mandan" % [
		total_height(), height, bottom_width, top_width, on]
