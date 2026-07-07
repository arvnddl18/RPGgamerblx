# Run in Blender: File > Scripting > Open > Run
# Re-exports VFX FBX without animation (fixes Roblox "Animation should not be empty")
import bpy
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = ["Dash_VFX.fbx", "LeapStrike_VFX.fbx", "LongShot_VFX.fbx", "StaffLightning_VFX.fbx"]
OUT = os.path.join(ROOT, "vfx_clean")
os.makedirs(OUT, exist_ok=True)

for name in FILES:
	src = os.path.join(ROOT, name)
	if not os.path.isfile(src):
		print("Skip missing:", name)
		continue
	bpy.ops.wm.read_factory_settings(use_empty=True)
	bpy.ops.import_scene.fbx(filepath=src)
	out = os.path.join(OUT, name)
	bpy.ops.export_scene.fbx(
		filepath=out,
		use_selection=False,
		apply_scale_options="FBX_SCALE_UNITS",
		bake_anim=False,
		add_leaf_bones=False,
		embed_textures=True,
		path_mode="COPY",
	)
	print("Exported:", out)
