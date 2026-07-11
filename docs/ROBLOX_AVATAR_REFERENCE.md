# Roblox Avatar Documentation — Reference Report

Source: [Create avatar items](https://create.roblox.com/docs/avatar) and the full **Learn → Avatar** section of the [Roblox Creator Hub](https://create.roblox.com/docs/llms.txt).

---

## 1. Sidebar / Navigation Structure

The Avatar section sits under **Learn → Avatar** in the Creator Hub. The sidebar is organized into five major areas:

| Section | Topics |
|---|---|
| **Overview** | Get started, Resources |
| **Create** | Bodies, Makeup, Accessories and clothing, Animations |
| **Accelerate** | Avatar Setup, Automatic Skinning Transfer, Accessory Fitting Tool, Photo-to-Avatar generation, Third-party tooling |
| **Monetize** | Overview, Marketplace, In-experience sales, In-experience creation |
| **Policies and Guidelines** | Marketplace, Intellectual property, Moderation, FAQ |

Breadcrumb path: **Learn / Avatar**

---

## 2. Landing Page — Create Avatar Items

### Core concept

Every Roblox user is represented by an **avatar** — a fully customizable character with cosmetics and accessories that **persist across games**.

Creators can build avatar bodies, items, and clothing, then upload them to the **Marketplace**, where millions of users browse and shop daily.

**CTAs on the page:** Watch overview · Visit Marketplace

---

### Section: Turn Your Creativity Into Virtual Assets

Roblox streamlines creation so you can focus on building with modern tools.

| Entry path | Description | Links |
|---|---|---|
| **Design a 2D classic shirt** | First basic 2D cosmetic using any image editor | Learn more |
| **Create a 3D accessory** | 3D modeling tool + Roblox Studio | Guides and tutorials · Get Blender · Get Studio |
| **Make 3D layered clothing** | Clothing that stretches, fits, and layers | Guides and tutorials · Get Blender · Get Studio |

---

### Section: What's New?

Latest videos and guides for beginners and pros. **See all videos**

| Topic | Detail |
|---|---|
| **Make your own shoes** | Advanced layered clothing type |
| **Convert body cages and clothing cages** | Convert body cage ↔ clothing cage; useful for advanced clothing/body creators |
| **Intro to UGC** | 3-part series with @ducksareyellow — Part 2: Modeling · Part 3: Texturing |

---

### Section: All the Tools You Need, for Free

Roblox handles moderation, localization, and payment processing for Marketplace uploads.

| Tool | Purpose | Links |
|---|---|---|
| **Blender** | Free open-source 3D modeling | Get Blender · Learn more |
| **Roblox Studio** | Convert custom models to Roblox-ready accessories | Get Studio · Accessory Fitting Tool · Avatar Setup |
| **Creator Hub** | Manage uploads, sales, policy, analytics | Go to Creator Hub · Upload and publishing guides |
| **Marketplace and beyond** | Home store (higher commission) or in-game avatar creation | Marketplace policy · Create your own home store · In-game creation |

---

### Section: Dive Deeper Into Avatars

| Topic | Detail | Links |
|---|---|---|
| **Fees, commissions, and more** | Upload fees, commission splits, revenue optimization | Fees and Commissions · Upload guides · Marketplace FAQs |
| **Marketplace and community policies** | Creator and community protection | Marketplace Policy · Intellectual Property · Moderation |
| **Create more complex items** | Advanced clothing, bodies, heads | Clothing guides · Character bodies · Animateable heads |
| **Build your own homestore** | Custom shop + higher commission split | Learn more |
| **In-game creation** | Let players build avatar items in your game (advanced) | Learn more |

---

## 3. Resources Page

Downloadable assets for avatar creation:

### Categories

1. **References** — Finished assets for reference
2. **Auto-Setup References** — Assets meeting Avatar Auto-Setup requirements
3. **Project Files** — Rigs, cages, fundamental building blocks
4. **Mannequins** — Sizing reference models
5. **Templates** — Prebuilt characters needing minor customization
6. **Add-ons and Tools** — Third-party plugins

### Higher-fidelity rigs (extra bones for hands, shoulders, spine)

| Asset | Contents |
|---|---|
| **Mannequin** | AA avatar-ready body, dynamic head, fingers, layered clothing, 2K PBR textures |
| **Robuta** | Anime-style body, dynamic head, fingers, layered + rigid accessories, 2K PBR |
| **HipToBeSquare** | Blocky-style body, dynamic head, fingers, layered + rigid accessories, color/roughness/metal PBR |
| **Roxie** | Avatar-ready body, dynamic head, fingers, layered + rigid accessories, PBR. Import with **Rig Scale: Rthro Narrow** |

### Standard rigs

| Asset | Notes |
|---|---|
| **Nature Girl** | Body + clothing + rigid accessories; Blender/Maya project files + PBR. Maya-origin armature may look rotated in Blender — does not affect performance |
| **Stylish Male** | Same as Nature Girl |
| **Fish Person** | Rigged, skinned, full body cage, facial animation rig, PBR. Antenna must be separate head accessory for Marketplace |
| **Goblin** | Rigged, skinned, full body cage, facial animation rig |
| **Blocky** | Blocky character, animatable head, full body cage |
| **Lola** | Skinned R15 from Skinning guide. **No inner/outer cage** — cannot equip layered clothing |
| **Tshirt - Uncaged** | Example clothing ready for caging |
| **Clothing Examples** | Caged 3D accessories + PBR |
| **Caging Examples** | From "How to cage Roblox's 3D clothing" video |

### Auto-setup references

- **Nature Girl - Auto-Setup** — Auto-Setup ready; **not compatible** with traditional avatar workflow
- **Stylish Male - Auto-Setup** — Same

### Project files (not for direct Studio import)

| File | Use |
|---|---|
| **R15 Rig and Attachments** | Standard armature for bodies and clothing (.blend, .ma, .fbx) |
| **Cages for Clothing** | Full-body inner + outer cage for clothing |
| **Cages for Bodies** | 15 individual body part cages |
| **Combined Project Files** | Rig skeleton + body cages + attachment points |

### Mannequins (scale/caging reference only — not for upload)

| Mannequin | Proportions |
|---|---|
| **Classic Mannequin** | Classic avatar proportions |
| **Rthro Mannequin** | Rthro Normal proportions |
| **Rthro Slender Mannequin** | Rthro Slender proportions |

Each includes a caged `.fbx` with individual outer body cages.

### Templates

- Multiple style templates (Male/Female) in Blender and `.fbx`
- **Warnings:**
  - Must perform cleanup steps before Marketplace validation
  - Eyebrow/eyelash versions may not be fully compatible with template body — see Makeup docs

### Add-ons and tools

| Tool | Purpose |
|---|---|
| **Blender Studio Plugin** | Upload assets directly from Blender to Studio |
| **Blender Validation Tool** | Verify avatar technical compatibility pre-import |
| **Blender Calisthenics Tool** | Check skinning data on characters and clothing |

---

## 4. Create — Bodies (Character Bodies)

**Doc:** [Character bodies](https://create.roblox.com/docs/avatar/character-bodies)

### Prerequisites

- Advanced 3D modeling (Blender/Maya)
- Understanding of avatar components and creation process
- Review basic character creation tutorial first

### Avatar components

#### Rendered

| Component | Detail | Studio representation |
|---|---|---|
| **Body parts** | 15 mesh objects, standard naming | `MeshPart` under a `Model` |
| **Textures** | Color/surface; transparency for skin tones | `SurfaceAppearance` or `MeshPart.TextureID` |

#### Non-rendered

| Component | Detail | Studio representation |
|---|---|---|
| **Rigging armature** | 16 bones (15 body parts + root); standard hierarchy/naming | `Bone` objects |
| **Face animation data** | Facial bones, skinning, timeline, mapped poses | `FaceControls` |
| **Cage meshes** | Outer boundary for layered clothing fit | `WrapTarget` |
| **Attachments** | 19 attachment points for rigid accessories | `Attachment` |

**Rig detail:** Standard = 15 poseable bones. Higher-fidelity = up to 37 additional bones (articulated hands, shoulders, spine).

**Cage warning:** Use Roblox body cage project files. Adding/removing cage vertices causes clothing fit issues.

**Modesty warning:** Body textures must include a modesty layer over sensitive regions (Community Standards).

### Creation workflows

1. **Basic with templates** — Customize a Roblox template with all required components
2. **Advanced from scratch** — Full custom control

Export all components in a single `.fbx` or `.gltf`.

### Sub-pages under Bodies

| Page | Content |
|---|---|
| Character specifications | Technical requirements for custom characters |
| Avatar project files and references | Downloadable project files |
| Export character bodies | Maya/Blender → Studio-ready `.fbx` |
| Import character bodies | Importer → test → upload |

---

## 5. Create — Makeup

**Doc:** [Makeup](https://create.roblox.com/docs/avatar/makeup)

Makeup is a cosmetic applied to avatar/NPC faces: eyeshadow, lipstick, blush, face paint, battle markings, camouflage.

### Structure

- Multiple specialized texture layers baked into a `Decal`
- Each layer = unique component (lips, eyes, face)
- Players buy complete looks or swap individual components on Marketplace
- Optional **eyebrows** and **eyelashes** as `Model` → `MeshPart` with skinning + caging

### Face regions

| Region | Notes |
|---|---|
| **Eyes** | Overlaps with other regions for seamless looks |
| **Lips** | Overlaps with other regions |
| **Face** | Overlaps with other regions |

**Marketplace limit:** Up to **6 total `Decal` objects** per makeup asset (any combination of regions).

### Template types

- **Mesh template** (recommended): Easier, mimics real-world makeup; higher-fidelity mesh/UVs
- **Cage template**: Single texture transfer; may transfer more accurately
- **Cannot switch** between templates mid-creation

### Template resources

- Template textures: Photoshop/GIMP, Substance Painter, Procreate (realistic + blocky variants)
- Template heads: Blender, Maya, FBX/GLTF (realistic + blocky)
- **Reference game:** `MakeupBeta.zip` on GitHub — only way to test makeup currently

### Creation process (summary)

1. Download reference template head + texture templates
2. Modify textures in image editor / PBR software
3. Reassign textures in Blender/Maya
4. Review face caging best practices
5. Export `.fbx`/`.gltf` with makeup-specific settings:
   - **Blender:** Enable Custom Properties; Armature → Only Deform Bones
   - **Maya:** Deformed Models → Skins enabled
6. Import to Studio → auto-generates `Decal` objects
7. Apply to characters in test place via `Makeup` or `Accessories` folders
8. Playtest

### Sub-pages

| Page | Content |
|---|---|
| Makeup specifications | Technical requirements |
| Reassign textures | Replace head template textures with custom |
| Import into Studio | Import workflow |

---

## 6. Create — Rigid Accessories

**Doc:** [Rigid accessories](https://create.roblox.com/docs/avatar/rigid-accessories)

Basic 3D cosmetics: props, weapons, hats. Attach to a specific point — **no deformation**.

### Components

| Component | Studio type |
|---|---|
| Single mesh | `MeshPart` under `Model` |
| Textures | `SurfaceAppearance` or `MeshPart.TextureID` |
| Attachment | `Attachment` (geometry with "Att" suffix auto-converts) |

### Sub-pages

| Page | Content |
|---|---|
| Rigid accessory specifications | Technical requirements |
| Body scale and proportions | Classic, Rthro, Rthro Slender sizing |
| Export rigid accessories | Maya/Blender export settings |
| Import rigid accessories | Importer → Accessory Fitting Tool |

### Body scale reference

| Scale | Height | Shape | `AvatarPartScaleType` |
|---|---|---|---|
| **Classic** | ~4.75 studs | Blocky | `Classic` |
| **Rthro Normal** | ~5.75–6.5 studs | Wider shoulders, narrower hips | `ProportionsNormal` |
| **Rthro Slender** | ~5.25–6.25 studs | Narrower shoulders, wider hips | `ProportionsSlender` |

Layered clothing auto-stretches over any scale. Rigid accessories need scale consideration.

---

## 7. Create — Layered Clothing

**Doc:** [Layered clothing](https://create.roblox.com/docs/avatar/layered-accessories)

3D cosmetics that **stretch, fit, and layer** over any body type: pants, t-shirts, jackets, dresses, shoes.

### Components (beyond rigid)

| Component | Purpose | Studio type |
|---|---|---|
| Mesh part | Geometry | `MeshPart` |
| Textures | Surface appearance | `SurfaceAppearance` / `TextureID` |
| Attachments | Ragdoll/dismemberment association | `Attachment` (auto-generated by AFT) |
| Rigging armature | Natural movement with character | Skinning data on mesh |
| Inner cage | Inner surface where clothes wrap | `WrapLayer` |
| Outer cage | Outer surface for additional layering | `WrapLayer` |

**For in-game equipping/config:** See Character appearance docs (not Marketplace creation).

**Classic clothing:** 2D decals on character surface — separate workflow.

### Sub-pages

| Page | Content |
|---|---|
| Clothing specifications | Mesh, cages, rigging requirements |
| Accessory project files and references | Downloadable files |
| Caging best practices | In-depth caging guidance |
| Layered clothing export settings | Maya/Blender export |
| Import clothing accessories | Importer → AFT |

---

## 8. Create — Classic Clothing (2D)

**Doc:** [Classic clothing](https://create.roblox.com/docs/avatar/classic-clothing)

**Warning:** Many Marketplace avatars no longer support 2D classic clothing. Prefer 3D cosmetics for modern avatars.

### Types

| Type | Format | Coverage |
|---|---|---|
| **T-shirt** | Square image (e.g. 512×512) | Front torso of blocky character |
| **Shirt** | Template-based image | Torso + arms |
| **Pants** | Template-based image | Torso + legs |

### Template part sizes (Shirts/Pants)

| Shape | Size | Parts |
|---|---|---|
| Large square | 128×128 | FRONT, BACK |
| Tall rectangle | 64×128 | Torso sides (R, L); arm/leg sides (L, B, R, F) |
| Wide rectangle | 128×64 | UP, DOWN |
| Small square | 64×64 | Arm/leg top/bottom (U, D) |

### Workflow

1. Choose type → create image → test in Studio → upload via web → pay fee → moderation → inventory copy

### Testing in Studio

1. Avatar tab → Character → Block Avatar rig
2. Insert `ShirtGraphic` (T-shirt), `Shirt`, or `Pants` under Rig
3. Set `Graphic`, `ShirtTemplate`, or `PantsTemplate` property to uploaded image

### Upload

Creator Dashboard → Avatar Items → Classics tab → drag/drop or Upload Asset

---

## 9. Create — Animations (Emotes)

**Doc:** [Emotes](https://create.roblox.com/docs/avatar/emotes)

Short animations: gestures, reactions, dances. Sold on Marketplace or in games.

### Components

- `Animation` object with `AnimationId` set to animation sequence asset ID
- Must meet technical specs, Marketplace policy, Community Standards

### Creation workflows

| Method | Tool |
|---|---|
| Animation Capture | Video → keyframe sequence |
| Manual | Animation Editor |
| Third-party | e.g. Moon Animator |

### Sub-pages

| Page | Content |
|---|---|
| Emotes specifications | Technical requirements |
| Animation export settings | Maya/Blender export |
| Import and configure animations | Importer workflow |

---

## 10. Create — Dynamic Heads

**Doc:** [Heads](https://create.roblox.com/docs/avatar/dynamic-heads)

Heads enable:

- Default custom facial expressions
- Emotes combining face + body animation
- Face accessories that deform with expressions (e.g. facial hair)

### Sub-pages

| Page | Content |
|---|---|
| Head validation | How Roblox validates head assets |
| Head specifications | Expected head schemas for Marketplace |
| Face caging best practices | Optimize face cages |
| Test heads in Studio | Import, equip face accessories, save |
| FACS poses reference | Facial Action Coding System pose reference |

**Marketplace requirement:** Minimum **17 FACS controls** including happiness and sadness expressions.

---

## 11. Accelerate — Avatar Setup

**Doc:** [Avatar Setup](https://create.roblox.com/docs/avatar-setup)

Auto-processes custom models into avatar assets. Can add missing components:

| Feature | What it does |
|---|---|
| **Rigging** | R15 armature |
| **Skinning** | Weights/influences for organic movement |
| **Facial animation** | FACS poses, facial rigging, skinning, animation data |
| **Caging** | Cages for layered clothing support |
| **Partitioning** | Split body mesh into 15 R15 parts |
| **Creating attachments** | Attachment points for rigid accessories |

### Import workflow

1. Home tab → Import → select `.fbx`/`.obj`/`.gltf`
2. Disable "Upload To Roblox" in Import Preview
3. Optional: save import preset
4. Fix warnings/errors → Import

**Warning:** Imported models go to moderation queue.

### Supported asset types

| Input | Output |
|---|---|
| Avatar body (`Model` with `MeshPart`s) | `Model` with 15 `MeshPart`s + avatar components |
| Accessory (must bundle with body) | `Accessory` (rigid) |
| Layered clothing (optional body bundle) | `Accessory` (layered) |
| Folder bundle (body + accessories/clothing) | Body + equippable `Accessory` items |

### Presets

| Preset | Use |
|---|---|
| **Platform Avatar** | Marketplace — restrictive, passes validation |
| **Development Avatar** | NPCs/starter characters — less restrictive |

### Asset types in Configure Models

- **Body** — character geometry
- **Layered** — layered clothing
- **Rigid** — rigid accessories
- **Eye Layered** — eyebrows/eyelashes

### Specialty settings

| Setting | Purpose |
|---|---|
| Handle face as 2D decal | Convert face decal → dynamic head |
| Create R15 with optional joints | Higher-fidelity rig |
| Manually Align Front | Fix front direction (negative Z-axis) |
| Improve facial caging | Better head cage alignment (important for makeup) |
| Reduce triangle count | Toggle auto-decimation (Development Avatar only) |

### Testing tools (side navigation)

**Check Body:**

- **Animations** — walk, jump, swim, etc.
- **Clothing** — layered clothing fit test
- **Accessories** — attachment point test
- **Body** — skin tone and body part swap

**Check Face:**

- **Animations** — eyeballs, eyebrows, mouth
- **Body** — skin tone, head swap
- **Makeup** — test makeup looks/components
- **Accessories** — hair, head, face accessories

**Test in Experience** — playtest with current setup

**Add test items** — from project or by AssetID

### Editing tools

- **Attachment Tool** — move attachment points
- **Cage Brush** — modify body cage (symmetrical, radius/falloff, real-time clothing preview)

### Publish

Save → Asset Configuration → upload to inventory or publish to Marketplace (upload fee + moderation required)

---

## 12. Accelerate — Automatic Skinning Transfer

**Doc:** [Automatic Skinning Transfer](https://create.roblox.com/docs/avatar/automatic-skinning-transfer)

Generates skinning data at runtime — no manual skinning required for layered clothing/facial accessories.

### `WrapLayer.AutoSkin` values

| Value | Behavior |
|---|---|
| `Disabled` | Default — no auto-skinning |
| `EnabledOverride` | Auto-skin; overrides existing skinning |
| `EnabledPreserve` | Auto-skin; preserves existing skinning if present |

### Special joints for eyelashes/eyebrows

- **`RBX_Leader`** — standard transfer
- **`RBX_Follower`** — transfers based on nearest leader vertex
- Must be beneath Root joint
- For Marketplace: vertices must be weight 1.0; eyebrow/eyelash types **require** these joints + `EnabledOverride`
- Body part meshes with these joints are **rejected**

### Suggested AutoSkin by category

| Category | Setting |
|---|---|
| Beard, Eyebrow, Eyelash | `EnabledOverride` |
| Hair, Hat, Glasses | `Disabled` |
| Shirt, Pants, Shoes | `EnabledOverride` or `EnabledPreserve` |

**Warning:** Partial cages rejected for Marketplace (OK for in-game only).

---

## 13. Accelerate — Accessory Fitting Tool (AFT)

**Doc:** [Accessory Fitting Tool](https://create.roblox.com/docs/avatar/accessory-fitting-tool)

Test custom models on multiple body types, animations, and accessories before generating final `Accessory`.

### Setup

1. Select `MeshPart` or `Model`
2. Avatar tab → Accessory
3. Choose asset type: **Clothing** (layered) or **Accessory** (rigid)
4. Select specific `AssetType` and scaling (Classic / Proportions Slender / Proportions Normal)

### Testing

- Different bodies (Bazooka Bones, Goblin, etc.)
- Different clothing (layer order via drag-and-drop)
- Different animations (walk, emotes)
- Custom assets from workspace (+ button)
- Playtest at any point

### Editing

**Layered clothing:**

- Cage editing (inner/outer vertices, falloff distance, opacity)
- Auto-skinning toggle (`EnabledPreserved` vs `EnabledOverride`)

**Rigid accessories:**

- Position/rotate/scale within bounding box (red = out of bounds)

### Generate

"Generate MeshPart Accessory" → creates proper `Accessory` hierarchy with `AccessoryType` and attachments.

---

## 14. Accelerate — Photo-to-Avatar Generation

**Doc:** [Photo-to-Avatar generation](https://create.roblox.com/docs/avatar/avatar-generation)

**Status:** Alpha. Requires scripting experience.

### Flow

1. **Request session** — `AvatarCreationService:RequestAvatarGenerationSessionAsync()` (server)
   - Returns connection + waitTime
   - Session includes: SessionId, Allowed2DGenerations, Allowed3DGenerations, SessionTime
2. **Selfie + 2D preview** — `PromptSelectAvatarGenerationImageAsync` → `GenerateAvatar2DPreviewAsync` (server) → `LoadAvatar2DPreviewAsync` (client)
3. **3D avatar** — `GenerateAvatarAsync` → `LoadGeneratedAvatarAsync` → `Players.CreateHumanoidModelFromDescription`
   - Returns `EditableMesh` and `EditableImage` for continued editing
4. **Publish** — `PromptCreateAvatarAsync`

---

## 15. Accelerate — Third-Party Tooling

| Tool | Purpose |
|---|---|
| **Roblox Blender plugin** | Transfer assets Blender → Studio |
| **Calisthenics Tool** | Verify skinning quality |
| **Clothing Validation Tool** | Check common clothing issues in Blender/Maya pre-export |

---

## 16. Monetize — Overview

**Doc:** [Monetize avatar items](https://create.roblox.com/docs/en-us/monetize-avatar)

Eligible creators sell rigid accessories, layered clothing, and avatar bodies/heads on Marketplace or in games.

### Marketplace

- Central hub for bodies, heads, clothing, accessories, animations
- Access via web or Roblox App
- Sponsored item ads for discoverability
- **Not the same as Creator Store** (Creator Store = dev assets: models, images, plugins)

### In-game

- **Avatar Editor Service** — Marketplace access in games
- Game owner gets commission on in-game sales
- **Avatar Inspect Menu** — view, try on, purchase
- **UGC Homestore** template

### Commission splits — 3D Avatar Assets

**Marketplace purchase:**

| Party | Share |
|---|---|
| Creator | 30% |
| Affiliate (Roblox) | 40% |
| Platform | 30% |

**In-game purchase:**

| Party | Share |
|---|---|
| Creator | 30% |
| Affiliate (game owner) | 40% |
| Platform | 30% |

**Community-created Limiteds resale:**

| Party | Share |
|---|---|
| Reseller | 50% |
| Creator | 10% |
| Affiliate | 10% |
| Platform | 30% |

- Limiteds: 30-day holding period before resale
- Only Roblox Plus members can resell Limiteds
- Only Roblox-created Limiteds are tradeable (currently)
- Robux from trading/selling items you didn't create = **not earned** (ineligible for DevEx)

---

## 17. Monetize — Marketplace (Detailed)

**Doc:** [Marketplace overview](https://create.roblox.com/docs/en-us/marketplace)

### Upload fees

| Type | Fee |
|---|---|
| 2D (T-shirt, Shirt, Pants) | 10 Robux per submission |
| 3D (accessories, bodies, animations) | 300 Robux per submission |

Fees generally **not refunded** if rejected by moderation.

### Publishing advances (3D, non-limited)

| Asset type | Non-limited | Paid limited |
|---|---|---|
| Hat, Face | 1500 | 13000 |
| Hair | 1000 | 6000 |
| Neck, Shoulder, Front, Back, Waist | 1000 | 15000 |
| Jacket, T-Shirt, Shirt, Sweater, Pants, Dress/Skirt, Shorts, Shoes | 600 | 5000 |
| Body | 2500 | 20000 |
| Head | 1500 | 10000 |
| Emotes | 1500 | 10000 |

Publishing advance is **refundable** via rebates from sales (30% creator commission applied to rebates). Processed once daily.

### Commissions (with 30-day escrow)

| Item type | Marketplace | In-game |
|---|---|---|
| 3D assets | Creator 30% | Creator 30%, Game owner 40% |
| Classic clothing | Creator 70% | Creator 60%, Game owner 10% |

### Progressive revenue share (Marketplace only)

Higher price above asset type floor → higher creator share:

| Price floor multiple | Creator share |
|---|---|
| 1× | 30% |
| 1.3× | 37% |
| 1.5× | 41% |
| 2× | 50% |
| 2.5× | 57% |
| 3× | 62% |
| 3.5× | 65% |
| 4× | 67% |
| 5× | 69% |
| 6×+ | 70% (cap) |

In-game purchases always receive base 30%.

### Timed options

Available for 3D shirts, pants, sweaters. Users rent for 3, 7, or 14 days at reduced cost. Enable in bulk or per item.

### Limiteds

- Per-unit fee for free Limiteds (market-based pricing)
- Rate limits: 9 purchases/min/user; 1 request/2s/item/user; max 3 purchases/user/item
- In-game: 60-second minimum in game before purchase

### Marketplace asset categories

**Rigid:** Hair, Hat, Face, Neck, Shoulder, Front, Back, Waist, Body suits (auto), Full masks (auto)

**Layered:** T-Shirt, Shirt, Sweater, Pants, Dress/Skirt, Shorts, Shoes, Body suits (auto), Full masks (auto)

**Bodies/Heads:** Body, Head

**Animations:** Emotes

**Classic:** Classic T-shirts, Shirts, Pants

---

## 18. Monetize — In-Experience Sales

| Feature | Detail |
|---|---|
| **Avatar items** | Sell community-created avatar items exclusively through your game |
| **UGC Homestore** | Customizable shop template for published items |

### UGC Homestore features

- **Mannequins** — 3D displays with purchasable items (attributes: `accessoryIds`, `bundleIds`, `poseAnimation`, `skinColor`)
- **Integrated shop** — bottom-screen catalog button
- **Modular building parts** — customizable shopfront
- Access via Studio: File → Open from Roblox → Templates

**Third-party catalog:** Enable "Allow Third Party Sales" in Experience Settings; set `DEFAULT_CREATOR_NAME` in `ReplicatedStorage.Settings`

---

## 19. Monetize — In-Experience Creation

**Doc:** [Avatar in-experience creation](https://create.roblox.com/docs/avatar/in-experience-creation)

Players create, customize, and purchase avatar bodies in real time. Purchased bodies save to Roblox inventory.

**Limitations:**

- Assets **not listed** on Marketplace
- **Cannot be resold or traded**
- Currently **bodies only** (not accessories/clothing)

### Key APIs

| Class | Purpose |
|---|---|
| `AvatarCreationService` | Prompting, validation, publishing |
| `EditableImage` | Runtime texture editing |
| `EditableMesh` | Runtime mesh editing |
| `WrapDeformer` | Runtime cage deformation (maintains skinning/FACS) |

### Requirements

- Base body meeting 15-part specifications + minimum FACS controls
- **Avatar creation tokens** (Robux purchase) for pricing/sales
- `HumanoidDescription` with 6 `BodyPartDescription` children (Head, Torso, RightLeg, LeftLeg, RightArm, LeftArm)
- Each of 15 `MeshPart`s needs `EditableImage` + `WrapDeformer` with `EditableMesh`
- Optional: `AccessoryDescription` for hair (EditableImage + EditableMesh, no WrapDeformer)

### Publish

`AvatarCreationService:PromptCreateAvatarAsync(tokenId, player, humanoidDescription)`

### Attribution

Created avatars link back to originating experience. Handle via `Player:GetJoinData()` → `GameJoinContext.JoinSource = CreatedItemAttribution`

**Demo:** Roblox Avatar Creator demo experience

---

## 20. Policies and Guidelines

### Creator requirements

**2D items:**

| Action | Individual | Group |
|---|---|---|
| Upload | 10 Robux | 10 Robux |
| Publish | Plus/Premium 1000/2200 + 10 Robux advance | Publishing user: Plus/Premium + advance; Group owner: Plus/Premium |
| Keep on-sale | Plus/Premium 1000/2200 | Group owner: Plus/Premium |

**3D items:**

| Action | Individual | Group |
|---|---|---|
| Upload | ID verification + 300 Robux | Uploading user: ID verification + Plus/Premium + 300 Robux |
| Publish | ID verification + Plus/Premium + 600–2500 advance | Publishing user: ID verification + Plus/Premium + advance; Group owner: Plus/Premium |
| Keep on-sale | ID verification + Plus/Premium | Group owner: Plus/Premium |

### General creation guidelines

- Follow Community Standards (no political, religious, gory, violent, self-harm, drug, sexual content)
- No Roblox official assets/branding in items
- No copies of existing Limiteds or other creators' items
- Only sell items you have IP permission for
- Test mouth/waist items on multiple character types
- No items that obscure avatar, UI, or other players' views
- No items exploiting platform glitches
- No excessive text
- No miscategorization

### Accessory/clothing categorization rules

- Complete hairstyles → Hair; partial → Hat/Face/Hair
- Facial hair → Face
- Above-neck items → Hat or Face
- Shoulder-only → Shoulder
- Tops: T-Shirt, Shirt, Jacket, Sweater
- Bottoms: Shorts, Pants, Skirt/Dress
- Hat designs → Hat category
- Facial anatomy components → Face
- Bodysuits auto-detected

### Avatar body guidelines

**Body parts allowed:**

- 1 right arm (upper, lower, hand)
- 1 left arm (upper, lower, hand)
- 1 torso (upper, lower)
- 1 right leg (upper, lower, foot)
- 1 left leg (upper, lower, foot)
- 1 head (caged, mouth region, 1–2 eye regions, 17 min FACS controls)
- Optional: eyebrows, eyelashes

**No accessories/clothing on body uploads** — sell separately (tails, wings, glasses, tattoos, makeup, etc.)

**Modesty layers required when:**

- Human-like character with smooth, flat skin-like texture in groin/chest

**Modesty layers optional when:**

- Animal or inanimate object characters

**Modesty rules:**

- Fully opaque, different color from skin tone
- No lingerie/suggestive designs
- Minors: both upper and lower torso coverage required
- Upper: full breast coverage (cleavage outlines OK if covered); back coverage recommended
- Lower: full coverage hips to bottom of groin/buttocks

**Makeup on heads:**

- Allowed: dimension shading, single-color lips, eyeliner, eyelashes, eyebrows, flushed cheeks
- Not allowed on body upload: multicolor features, face painting, eyeshadow beyond skin-tone shading → sell separately

**Textures vs tattoos:**

- Textures = repeating physical pattern covering ≥50% (scales, fur, feathers)
- Tattoos = distinct drawings/patterns → sell separately

### UGC Validation System

Runs on Marketplace upload and `AvatarCreationService` API calls.

**Validation categories:**

| Category | Checks |
|---|---|
| Schema | Hierarchy, child types, tags, attributes, banned scripts |
| Mesh geometry | Triangle budgets, bounding box, surface area, watertight, no N-gons/vertex colors/degenerate triangles |
| Texture/materials | Max resolution, valid UVs, PBR validation |
| Rigging/skinning | Bodies/layered need skinning; rigid must not; weight count = vertex count |
| Cages | All body parts caged, watertight, match render mesh, UVs match templates |
| Attachments | Correct naming, position, orientation |
| Dynamic head | 17+ FACS, cage landmarks, blink/mouth/happy/sad detection |
| Security | Creator validation, banned classes, anti-spoofing |

**Visualization tools:** Beta feature "Visualizing UGC Validation" + UGC Validation plugin with checks like `Measure_Cage_Distance_Head`, `Measure_Dynamic_Head`, `Measure_Cage_UV`, etc.

### Related policy pages

- [Intellectual property](https://create.roblox.com/docs/marketplace/intellectual-property)
- [Moderation](https://create.roblox.com/docs/marketplace/moderation)
- [FAQ](https://create.roblox.com/docs/marketplace/frequently-asked-questions)

---

## 21. Related Game Development APIs & Services

These appear in the broader docs under Learn/Avatar connections:

### Engine services (in-experience)

| Service | Use |
|---|---|
| `AvatarEditorService` | Access user avatar, inventory, Marketplace |
| `AvatarCreationService` | In-experience avatar creation/generation |
| `MarketplaceService` | In-experience transactions |
| `UGCValidationService` | Validation checks |

### Key classes

| Class | Role |
|---|---|
| `Accessory` / `AccessoryDescription` | Wearable items |
| `BodyPartDescription` | Body part appearance |
| `WrapLayer` / `WrapTarget` / `WrapDeformer` | Layered clothing/caging |
| `FaceControls` | Facial animation |
| `HumanoidDescription` | Full avatar configuration |
| `Clothing` / `Shirt` / `Pants` / `ShirtGraphic` | Classic 2D clothing |

### Player UI features

- Avatar Editor Service
- Avatar Inspect Menu (view, try on, purchase)
- Avatar Context Menu (ACM)

### Developer modules (relevant to avatars)

- **Merch Booth** — sell avatar assets, passes, products in-game
- **Emote Bar** — accessible emote interaction
- **Social Interactions** — avatar expression/movement
- **Selfie Mode**, **Photo Booth**

---

## 22. Complete Doc Tree Under Learn → Avatar

```
Learn / Avatar
├── Overview
│   ├── Create avatar items (landing page)
│   └── Resources (downloads)
│
├── Create
│   ├── Bodies
│   │   ├── Character bodies
│   │   ├── Character specifications
│   │   ├── Avatar project files and references
│   │   ├── Export character bodies
│   │   └── Import character bodies
│   ├── Makeup
│   │   ├── Makeup
│   │   ├── Makeup specifications
│   │   ├── Reassign textures
│   │   └── Import into Studio
│   ├── Rigid accessories
│   │   ├── Rigid accessories
│   │   ├── Rigid accessory specifications
│   │   ├── Body scale and proportions
│   │   ├── Export rigid accessories
│   │   └── Import rigid accessories
│   ├── Layered clothing
│   │   ├── Layered clothing
│   │   ├── Clothing specifications
│   │   ├── Accessory project files and references
│   │   ├── Caging best practices
│   │   ├── Layered clothing export settings
│   │   └── Import clothing accessories
│   ├── Accessories and clothing
│   │   └── Classic clothing
│   ├── Animations (Emotes)
│   │   ├── Emotes
│   │   ├── Emotes specifications
│   │   ├── Animation export settings
│   │   └── Import and configure animations
│   └── Dynamic heads
│       ├── Heads
│       ├── Head validation
│       ├── Head specifications
│       ├── Face caging best practices
│       ├── Test heads in Studio
│       └── FACS poses reference
│
├── Accelerate
│   ├── Avatar Setup
│   │   └── Avatar Setup model requirements
│   ├── Automatic Skinning Transfer
│   ├── Accessory Fitting Tool
│   ├── Photo-to-Avatar generation
│   └── Third-party tooling
│       ├── Roblox Blender plugin
│       ├── Calisthenics Tool
│       └── Clothing Validation Tool
│
├── Monetize
│   ├── Monetize avatar items (overview)
│   ├── Marketplace
│   │   ├── Marketplace overview
│   │   ├── Marketplace fees and commissions
│   │   ├── UGC validation system
│   │   ├── Publish to Marketplace
│   │   ├── Custom thumbnails
│   │   ├── Sponsored items
│   │   ├── Marketplace policy
│   │   └── Marketplace asset categories
│   ├── In-experience sales
│   │   ├── Avatar items
│   │   └── UGC Homestore
│   └── In-experience creation
│       ├── Avatar in-experience creation
│       └── Avatar creation token
│
└── Policies and Guidelines
    ├── Intellectual property for avatar items
    ├── Moderation
    └── Frequently asked questions
```

---

## 23. Game Development Takeaways (RPG Context)

For your RPG project, the most relevant areas are:

1. **Character appearance in-game** — How avatars equip layered clothing, rigid accessories, and display correctly (Character appearance docs, `HumanoidDescription`, `WrapLayer`)
2. **Avatar Editor Service / Inspect Menu** — Let players browse and buy Marketplace items in your game (40% commission to you)
3. **Merch Booth module** — Sell avatar assets directly in-game
4. **R6 to R15 Adapter** — If supporting legacy R6 games with R15 avatars
5. **Adaptive Animation** — Universal animation/emote sets across body types
6. **In-experience creation** — Advanced: let players design custom bodies (requires tokens, `EditableMesh`/`EditableImage`/`WrapDeformer`)
7. **Validation system** — If you plan custom UGC bodies/accessories for your game, understand cage/rig/FACS requirements even for non-Marketplace assets
8. **Body scales** — Classic vs Rthro vs Rthro Slender affects rigid accessory fit and world scale design (~4.75–6.5 studs tall)

---

For deep technical specs (triangle budgets, exact bone names, export settings), refer to the individual specification pages linked in section 22.
