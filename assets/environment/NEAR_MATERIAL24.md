# 伐木场高清近景材质样板24

2026-10-24，负责人同意先做伐木场周边局部对照，检验背景偏糊与建筑过精细的落差；非整图推广/验收。

- 文件：`assets/environment/sect_lumber_near24.png`，1536×1024，3902654字节。
- SHA256：`B4B9A8B6B1B660DA30C69DC80639ECBD0B49AD2217296360C9E39E39714E29A5`。
- 来源：内置ImageGen；编辑目标是`sect_sites_clear22.png`的Rect(345,270,330,220)原生截图，Godot工具`tests/prepare_material24_reference.gd`只裁取参考图，没有锐化或重绘。编辑参考保存在`builds/material24-reference.png`。
- 第二输入`lumber-contact20.png`仅作清晰材质/边缘参考，不将建筑烘焙进底图；来源沿用LUMBER_CONTACT20.md。建筑PNG及图集未改。
- 生成缓存：`C:/Users/72736/.codex/generated_images/01a142b2-f60d-7421-8760-8fc6289a81ab/exec-245ff086-fc0f-468c-b0dd-7352e7687809.png`，原样复制入项目、保留原缓存，无Python改图/本地重编码。
- 按工具适用条件用于本项目，不宣称独占版权或原生3D素材。生产素材为新生成的位图近景，不是靠锐化旧小图恢复真实细节。
- 运行映射回原330×220区域、边缘羽化，原地块几何、建筑及UI照常叠加；远景、其他院落不重做。生成的草丛/石缝等细节有所变化，不声称局部所有景物逐像素保形。
- 首次缩小出现碎噪点，新图导入开启mipmaps，SectMap选LINEAR_WITH_MIPMAPS。其余现有素材未启用mips；1920关闭样板的基线整图与旧线性采样对照RGB差异为空，未把全图建筑一起模糊。
- 状态：TESTED / 待负责人原生尺寸视觉确认。新近景略偏亮、偏黄绿；尚不能证明与整个场景完全统一。

## 完整提示词

Use case: precise-object-edit. Asset type: HIGH-RESOLUTION LOCAL TERRAIN PATCH for an existing Chinese cultivation game. Image 1 is the EDIT TARGET, a small330x220 crop of the existing background; Image 2 is MATERIAL/EDGE-QUALITY REFERENCE ONLY (do NOT insert the building). Reconstruct Image1 at1536x1024, same3:2 landscape framing and EXACT same elevated isometric camera, paths, grass clearing, low limestone boulders, lantern positions, heights, silhouettes, ground-plane directions, sunlight direction and muted palette. Change material definition and drawing finish ONLY: replace blurry melted brushwork with clearly structured weathered ivory limestone, readable stone joints, layered moss/short grass clumps, well-defined rock planes and precise but restrained foliage edges, matching the semi-realistic game material clarity of the building in Image2. This is nearby playable ground, NOT distant atmospheric scenery: all of this local patch must be in focus, no depth-of-field, no haze, no smeared foliage. Keep detail at believable scale: no giant grass blades, no enlarged rocks, no excessively busy micro-grain. Warm soft upper-left daylight, gentle neutral ambient occlusion, realistic restrained painted game materials, not a photo, not cel shaded, not chibi. Preserve the central open low grass/beige earth clearing for the runtime building. DO NOT add a building, sky, island, stairs, people, signs, new props, rectangular plot border, diamond slab, regular inner paving grid, text, UI, labels, watermark, dark vignette or sharpened halos. Outer20percent must closely preserve Image1's value/palette and path continuation so this can feather into the original map; do not change the composition or zoom. Goal: match the nearby terrain clarity to the existing crisp building sprite while retaining exactly the old layout. Output one opaque1536x1024 PNG.
