# 主殿场景样板资产

- 日期：2026-10-19。
- 工具：OpenAI内置ImageGen（imagegen技能默认模式），没有使用CLI或外部下载素材。
- 运行文件：`main-hall-sample.png`；原始生成文件仍保留在Codex generated_images目录。
- SHA-256：82A93454A00F4577A6B6B3F11426010AF81701BD2E3077363E611D53906C537D。
- 用途：《青云宗》V0.8主殿局部样板，独立透明建筑；不是整张地图或UI，不包含游戏文字。
- 来源：根据负责人提供的色彩、材质、相机与主殿方向，以文字规格重新生成；没有把参考图作为贴图或改变逻辑坐标。
- 项目使用范围：运行时主殿视觉；透明边缘、比例、光影以Godot实际截图复核，尚待负责人验收。
- 视觉尺寸/脚点由SectMap.MAIN_HALL_VISUAL定义；主殿逻辑占地仍只有(4,3)，广场与接地影不影响放置和存档。

## 完整生成提示词

Use-case: stylized-concept game production asset. Generate ONE isolated grand main hall for a Chinese xianxia sect 2.5D isometric game, NOT a full scene. Style direction: epic yet restrained semi-realistic painted game art, crisp readable silhouette, blue-black glazed layered roofs, warm dark timber columns, ivory white stone low foundation, only small aged-gold ridge accents, muted teal blue and warm cream palette, upper-left sunlight and subtle soft lower-right contact shadow. Three-quarter orthographic isometric view, ground axes slope exactly approximately 26.565 degrees, diamond ground ratio 2:1. A majestic central hall with modest symmetrical wings, clearly grander than a small disciple residence. Complete structure fits inside a square transparent canvas with 8% clear padding; no clipping. LOW flat white-stone plinth and short steps ONLY, no giant separate floating rock or cliff island, no scenic background, no forest or surrounding buildings, no giant courtyard occupying most of image. Ground contact centered around x=50%, y=87% of canvas. Keep edges clean with actual alpha transparency, no dark/colored matte or baked rectangular gradient. No people, text, calligraphy, labels, grid, UI, watermark. This asset will be placed on an existing pale stone mountain terrace in Godot; prioritize natural contact and a solid readable architectural body at 250px game size.
