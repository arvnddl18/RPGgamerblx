import bpy
import json
import os

EXPORT_DIR = "C:/Users/User/Desktop/Roblox Project/exports/Crossbow"
os.makedirs(EXPORT_DIR, exist_ok=True)


def make_checker(name, ca, cb, size=512, cells=8):
    img = bpy.data.images.new(name, size, size, alpha=True)
    pixels = []
    a = (ca[0] / 255, ca[1] / 255, ca[2] / 255, 1.0)
    b = (cb[0] / 255, cb[1] / 255, cb[2] / 255, 1.0)
    cell = size // cells
    for y in range(size):
        for x in range(size):
            pick = a if ((x // cell) + (y // cell)) % 2 == 0 else b
            pixels.extend(pick)
    img.pixels = pixels
    path = os.path.join(EXPORT_DIR, name + ".png")
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    return img, path


def assign_mat(obj, mat_name, img):
    mat = bpy.data.materials.new(mat_name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    obj.data.materials.clear()
    obj.data.materials.append(mat)


bi, bp = make_checker("CrossbowBody_Diffuse", (74, 85, 104), (58, 68, 84))
hi, hp = make_checker("Handle_Diffuse", (42, 26, 10), (28, 16, 6))
assign_mat(bpy.data.objects["CrossbowBody"], "CrossbowBody_Mat", bi)
assign_mat(bpy.data.objects["Handle"], "Handle_Mat", hi)

fbx_path = os.path.join(EXPORT_DIR, "Crossbow.fbx")

bpy.ops.object.select_all(action="DESELECT")
for name in ["CrossbowBody", "Handle"]:
    bpy.data.objects[name].select_set(True)
bpy.context.view_layer.objects.active = bpy.data.objects["Handle"]

bpy.ops.export_scene.fbx(
    filepath=fbx_path,
    use_selection=True,
    object_types={"MESH"},
    apply_scale_options="FBX_SCALE_ALL",
    axis_forward="-Z",
    axis_up="Y",
    use_mesh_modifiers=True,
    mesh_smooth_type="FACE",
    path_mode="COPY",
    embed_textures=True,
)

body = bpy.data.objects["CrossbowBody"]
handle = bpy.data.objects["Handle"]
body.data.calc_loop_triangles()
handle.data.calc_loop_triangles()

STUD = 0.28
length_m = body.dimensions.z
summary = {
    "body_tris": len(body.data.loop_triangles),
    "handle_tris": len(handle.data.loop_triangles),
    "total_tris": len(body.data.loop_triangles) + len(handle.data.loop_triangles),
    "dimensions_m": {
        "x": round(body.dimensions.x, 4),
        "y": round(body.dimensions.y, 4),
        "z": round(body.dimensions.z, 4),
    },
    "dimensions_studs": {
        "x": round(body.dimensions.x / STUD, 2),
        "y": round(body.dimensions.y / STUD, 2),
        "z": round(body.dimensions.z / STUD, 2),
    },
    "handle_origin": [round(v, 4) for v in handle.location],
    "fbx_path": fbx_path,
    "body_tex": bp,
    "handle_tex": hp,
}
print(json.dumps(summary, indent=2))
