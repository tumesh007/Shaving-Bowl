import bpy
import math
import os
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.dirname(os.path.abspath(__file__))
BODY = os.path.join(ROOT, "travel_shaving_bowl.stl")
DRAWER = os.path.join(ROOT, "blade_drawer.stl")


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def material(name, color, metallic=0.0, roughness=0.42):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    return mat


BODY_MAT = material("Ceramic blue-gray", (0.43, 0.58, 0.68))
DRAWER_MAT = material("Drawer warm amber", (0.95, 0.52, 0.20))
BLADE_MAT = material("Blade steel", (0.68, 0.73, 0.77), 0.78, 0.24)
RAZOR_MAT = material("Razor handle", (0.16, 0.19, 0.22), 0.3, 0.28)


def import_mesh(path, name, mat):
    old = set(bpy.data.objects)
    bpy.ops.wm.stl_import(filepath=path)
    added = [obj for obj in bpy.data.objects if obj not in old]
    for obj in added:
        obj.name = name
        obj.data.materials.clear()
        obj.data.materials.append(mat)
        for polygon in obj.data.polygons:
            polygon.use_smooth = True
    return added


def add_body(with_drawer=True, open_drawer=False, blades=False):
    body = import_mesh(BODY, "Bowl and handle", BODY_MAT)[0]
    drawer = None
    if with_drawer:
        drawer = import_mesh(DRAWER, "Separate sliding drawer", DRAWER_MAT)[0]
        if open_drawer:
            drawer.location.y += 9.9
    if blades:
        for index in range(5):
            bpy.ops.mesh.primitive_cube_add(size=1, location=(
                53.5, 0.0, 4.825 + index * 0.37))
            blade = bpy.context.object
            blade.name = "Illustrative DE blade"
            blade.dimensions = (21.6, 42.6, 0.25)
            bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
            blade.data.materials.append(BLADE_MAT)
    return body, drawer


def cut_half(obj, axis, plane):
    if obj.data.users > 1:
        obj.data = obj.data.copy()
    center = [0.0, 0.0, 0.0]
    center[axis] = plane + 200.0
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    cutter = bpy.context.object
    cutter.name = "Temporary section cutter"
    cutter.dimensions = [400.0, 400.0, 400.0]
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    mod = obj.modifiers.new("Section cut", "BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.solver = "EXACT"
    mod.object = cutter
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(cutter, do_unlink=True)


def setup_camera(target, direction, scale):
    target = Vector(target)
    direction = Vector(direction).normalized()
    data = bpy.data.cameras.new("Preview camera")
    camera = bpy.data.objects.new("Preview camera", data)
    bpy.context.collection.objects.link(camera)
    camera.location = target + direction * 220
    camera.rotation_euler = (-direction).to_track_quat("-Z", "Y").to_euler()
    data.type = "ORTHO"
    data.ortho_scale = scale
    bpy.context.scene.camera = camera


def setup_lighting():
    world = bpy.data.worlds.new("Soft studio")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.23, 0.27, 0.31, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.8
    bpy.context.scene.world = world
    for name, location, power, size in [
        ("Key", (15, -75, 115), 80000, 70),
        ("Fill", (-95, -15, 55), 50000, 85),
        ("Rim", (50, 85, 95), 70000, 65),
    ]:
        data = bpy.data.lights.new(name, "AREA")
        data.energy = power
        data.shape = "DISK"
        data.size = size
        light = bpy.data.objects.new(name, data)
        bpy.context.collection.objects.link(light)
        light.location = location
        light.rotation_euler = (Vector((12, -2, 22)) - light.location).to_track_quat("-Z", "Y").to_euler()


def render(name, target, direction, scale):
    scene = bpy.context.scene
    setup_camera(target, direction, scale)
    setup_lighting()
    scene.render.engine = "BLENDER_EEVEE"
    scene.eevee.use_gtao = True
    scene.eevee.gtao_distance = 5
    scene.eevee.gtao_factor = 0.9
    scene.render.resolution_x = 1100
    scene.render.resolution_y = 825
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "Medium High Contrast"
    scene.view_settings.exposure = 0
    scene.view_settings.gamma = 1
    scene.camera.data.lens = 55
    scene.render.filepath = os.path.join(OUT, name)
    bpy.ops.render.render(write_still=True)


def standard_scene(name, target=(14, -1, 26), direction=(1, -1, 0.9), scale=135,
                   open_drawer=False, blades=False, parked_razor=False):
    clear_scene()
    body, drawer = add_body(True, open_drawer, blades)
    if parked_razor:
        dock_raise = 8
        axis = Vector((math.sin(math.radians(65)), 0, math.cos(math.radians(65))))
        center = Vector((42.0, 0, 34 + dock_raise))
        bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=5.4, depth=18,
                                            location=center + axis * 12)
        shaft = bpy.context.object
        shaft.name = "Illustrative assembled razor handle"
        shaft.rotation_euler = axis.to_track_quat("Z", "Y").to_euler()
        shaft.data.materials.append(RAZOR_MAT)
        head_pos = center + axis * 28.2
        bpy.ops.mesh.primitive_cube_add(size=1, location=head_pos)
        head = bpy.context.object
        head.name = "Generic razor head"
        head.dimensions = (9, 42, 7)
        head.rotation_euler = axis.to_track_quat("Z", "Y").to_euler()
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        head.data.materials.append(RAZOR_MAT)
    render(name, target, direction, scale)


def section_scene(name, axis, plane, direction, target, scale, blades=False, open_drawer=False):
    clear_scene()
    body, drawer = add_body(True, open_drawer, blades)
    cut_half(body, axis, plane)
    if drawer is not None:
        cut_half(drawer, axis, plane)
    render(name, target, direction, scale)


standard_scene("01-isometric.png")
standard_scene("02-top.png", target=(14, -1, 26), direction=(0, 0, 1), scale=122)
standard_scene("03-side.png", target=(14, -1, 26), direction=(0, -1, 0), scale=120)
standard_scene("04-bottom.png", target=(14, -1, 20), direction=(0, 0, -1), scale=122)
standard_scene("05-lather-surface-closeup.png", target=(0, 0, 13), direction=(0.2, -0.4, 1), scale=73,
               )
section_scene("06-texture-section.png", 1, 0, (0, 1, 0), (0, 0, 18), 115)
section_scene("07-handle-section.png", 1, 0, (0, 1, 0), (45, 0, 19), 76)
section_scene("08-centered-blade-compartment.png", 0, 53.5, (1, 0, 0), (53.5, 0, 7), 70, blades=True)
section_scene("09-blade-drawer-section.png", 0, 53.5, (1, 0, 0), (53.5, 0, 7), 70, blades=True)
standard_scene("10-razor-in-dock.png", parked_razor=True)
standard_scene("11-drawer-installed.png")
standard_scene("12-drawer-partially-open.png", open_drawer=True)
standard_scene("13-blades-inside-drawer.png", blades=True)

clear_scene()
import_mesh(BODY, "Bowl and half-round head shelf", BODY_MAT)
render("14-head-rest-closeup.png", target=(51, 0, 44), direction=(0.55, -1, 0.75), scale=48)

clear_scene()
import_mesh(BODY, "Embossed name on bowl exterior", BODY_MAT)
render("15-name-emboss-closeup.png", target=(-40, 0, 22), direction=(-1, 0, 0), scale=62)
