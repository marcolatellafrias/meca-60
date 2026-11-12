# LOS MODELOS DE PRUEBA DEL FLUJO DE PÍXELES (ver docs/pixel-art.md): una caja con la tapa en chanfle y una manija,
# modelada en quads SOBRE LA GRILLA DE PÍXELES (un píxel = 63 cm / 16), y su versión 2 con «un detallito» cambiado (la
# manija más larga y una chapa al frente) para probar que lo pintado sobrevive a remodelar. Sin UVs: Godot se arregla.
#
#   "C:/Program Files/Blender Foundation/Blender 4.5/blender.exe" -b --python tools/pixel_art_modelos_prueba.py -- game/pixel_art/models
import sys

import bmesh
import bpy

P = 0.63 / 16.0


def material(name, srgb):
    # Blender y glTF guardan el color LINEAL; Godot lo muestra en sRGB. Se escribe en sRGB, como en Godot.
    color = tuple(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb)
    made = bpy.data.materials.new(name)
    made.diffuse_color = (*color, 1.0)
    made.use_nodes = True
    made.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*color, 1.0)
    return made


def quad(bm, corners, slot):
    face = bm.faces.new([bm.verts.new((x * P, y * P, z * P)) for x, y, z in corners])
    face.material_index = slot


def box(bm, lo, hi, slot, bottom=True):
    (a, b, c), (d, e, f) = lo, hi
    quad(bm, [(a, b, f), (d, b, f), (d, e, f), (a, e, f)], slot)  # arriba
    if bottom:
        quad(bm, [(a, e, c), (d, e, c), (d, b, c), (a, b, c)], slot)
    quad(bm, [(a, b, c), (d, b, c), (d, b, f), (a, b, f)], slot)  # frente (-Y)
    quad(bm, [(d, e, c), (a, e, c), (a, e, f), (d, e, f)], slot)  # fondo
    quad(bm, [(d, b, c), (d, e, c), (d, e, f), (d, b, f)], slot)  # derecha
    quad(bm, [(a, e, c), (a, b, c), (a, b, f), (a, e, f)], slot)  # izquierda


def build(name, second):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mesh = bpy.data.meshes.new(name)
    mesh.materials.append(material("caja", (0.38, 0.39, 0.32)))
    mesh.materials.append(material("herraje", (0.2, 0.2, 0.21)))
    mesh.materials.append(material("chapa", (0.8, 0.75, 0.62)))
    bm = bmesh.new()
    # El cuerpo: 16 × 16 píxeles de planta, 12 de alto, sin tapa (la tapa es el chanfle).
    quad(bm, [(-8, 8, 0), (8, 8, 0), (8, -8, 0), (-8, -8, 0)], 0)
    quad(bm, [(-8, -8, 0), (8, -8, 0), (8, -8, 12), (-8, -8, 12)], 0)
    quad(bm, [(8, 8, 0), (-8, 8, 0), (-8, 8, 12), (8, 8, 12)], 0)
    quad(bm, [(8, -8, 0), (8, 8, 0), (8, 8, 12), (8, -8, 12)], 0)
    quad(bm, [(-8, 8, 0), (-8, -8, 0), (-8, -8, 12), (-8, 8, 12)], 0)
    # La tapa: cuatro caras inclinadas (fuera de la grilla: miden 2·√2 píxeles) y el techo de 12 × 12.
    quad(bm, [(-8, -8, 12), (8, -8, 12), (6, -6, 14), (-6, -6, 14)], 0)
    quad(bm, [(8, 8, 12), (-8, 8, 12), (-6, 6, 14), (6, 6, 14)], 0)
    quad(bm, [(8, -8, 12), (8, 8, 12), (6, 6, 14), (6, -6, 14)], 0)
    quad(bm, [(-8, 8, 12), (-8, -8, 12), (-6, -6, 14), (-6, 6, 14)], 0)
    quad(bm, [(-6, -6, 14), (6, -6, 14), (6, 6, 14), (-6, 6, 14)], 0)
    # La manija, apoyada en el techo.
    reach = 6 if second else 4
    box(bm, (-reach, -1, 14), (reach, 1, 16), 1, bottom=False)
    if second:
        # La versión 2: una chapa de un píxel de grueso al frente.
        box(bm, (-4, -9, 3), (4, -8, 8), 2, bottom=False)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bm.to_mesh(mesh)
    bm.free()
    item = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(item)
    bpy.ops.export_scene.gltf(filepath="%s/%s.glb" % (FOLDER, name), export_format="GLB", export_apply=True,
        export_yup=True)


def wedge(name):
    # UNA CUÑA, para ver los triángulos: 16 × 16 de planta, 12 de alto atrás y una rampa al frente (mide 20 píxeles:
    # 12, 16 y 20 es un triángulo 3-4-5). Sus dos costados son triángulos.
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mesh = bpy.data.meshes.new(name)
    mesh.materials.append(material("caja", (0.47, 0.4, 0.27)))
    bm = bmesh.new()
    quad(bm, [(-8, 8, 0), (8, 8, 0), (8, -8, 0), (-8, -8, 0)], 0)
    quad(bm, [(8, 8, 0), (-8, 8, 0), (-8, 8, 12), (8, 8, 12)], 0)
    quad(bm, [(-8, -8, 0), (8, -8, 0), (8, 8, 12), (-8, 8, 12)], 0)
    for x, order in ((8, 1), (-8, -1)):
        corners = [(x, -8, 0), (x, 8, 0), (x, 8, 12)][::order]
        face = bm.faces.new([bm.verts.new((a * P, b * P, c * P)) for a, b, c in corners])
        face.material_index = 0
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bm.to_mesh(mesh)
    bm.free()
    item = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(item)
    bpy.ops.export_scene.gltf(filepath="%s/%s.glb" % (FOLDER, name), export_format="GLB", export_apply=True,
        export_yup=True)


FOLDER = sys.argv[sys.argv.index("--") + 1]
build("caja", False)
build("caja_v2", True)
wedge("cuna")
