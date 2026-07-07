import pathlib

files = [
    ("ServerScriptService.Server.Services.FastTravelService", "ModuleScript", r"src\Server\Services\FastTravelService.lua"),
    ("StarterPlayer.StarterPlayerScripts.Client.UI.FastTravel.FastTravelUI", "ModuleScript", r"src\Client\UI\FastTravel\FastTravelUI.lua"),
    ("StarterPlayer.StarterPlayerScripts.Client.UI.FastTravel.FastTravelWorldMapUI", "ModuleScript", r"src\Client\UI\FastTravel\FastTravelWorldMapUI.lua"),
]
root = pathlib.Path(r"c:\Users\User\Desktop\Roblox Project")
out = root / ".studio_push"
out.mkdir(exist_ok=True)

for path, cls, src_rel in files:
    content = (root / src_rel).read_text(encoding="utf-8")
    parts = path.split(".")
    nav = []
    for i, p in enumerate(parts):
        if i == 0:
            nav.append(f'local current = game:GetService("{p}")')
        else:
            nav.append(
                f'current = current:FindFirstChild("{p}") or (function() local inst = Instance.new("Folder"); inst.Name = "{p}"; inst.Parent = current; return inst end)()'
            )
    code = "\n".join(nav) + f"""
local existing = current:FindFirstChild("{parts[-1]}")
if existing then existing:Destroy() end
local scriptInst = Instance.new("{cls}")
scriptInst.Name = "{parts[-1]}"
scriptInst.Source = [=[
{content}]=]
scriptInst.Parent = current
return "Created {path}"
"""
    (out / (parts[-1] + ".luau")).write_text(code, encoding="utf-8")
    print(parts[-1], len(content))
