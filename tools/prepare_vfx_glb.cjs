const fs = require("fs");
const path = require("path");
const assimpjs = require("assimpjs")();

const ROOT = path.join(__dirname, "..");
const OUT = path.join(ROOT, "vfx_clean");
const FILES = [
	"Dash_VFX.fbx",
	"LeapStrike_VFX.fbx",
	"LongShot_VFX.fbx",
	"StaffLightning_VFX.fbx",
];

async function main() {
	const ajs = await assimpjs;
	fs.mkdirSync(OUT, { recursive: true });

	for (const name of FILES) {
		const src = path.join(ROOT, name);
		if (!fs.existsSync(src)) {
			console.log("skip missing", name);
			continue;
		}

		const fileList = new ajs.FileList();
		fileList.AddFile(name, new Uint8Array(fs.readFileSync(src)));

		const result = ajs.ConvertFileList(fileList, "glb2");
		if (!result.IsSuccess() || result.FileCount() === 0) {
			console.error(name, "failed:", result.GetErrorCode());
			continue;
		}

		const outName = name.replace(/\.fbx$/i, ".glb");
		const outPath = path.join(OUT, outName);
		const content = result.GetFile(0).GetContent();
		fs.writeFileSync(outPath, Buffer.from(content));
		console.log("wrote", outPath, content.length, "bytes");
	}
}

main().catch(console.error);
