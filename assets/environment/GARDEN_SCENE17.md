# 候选17：按建筑风格重制完整园林背景

- 日期：2026-10-22，使用OpenAI内置ImageGen；未使用CLI或外部下载素材。
- 输入：本项目`main-hall-sample.png`和`disciple-quarters-sample.png`，仅作材质、风格和视角参考，来源沿用对应素材登记。未使用人物照片。
- 输出：`sect_garden_scene17.png`，实际1672×941，不透明PNG。提示词要求更高分辨率，但实际输出以上述尺寸为准，不宣称原生4K或3D模型。
- SHA256：`936193DF9C4E9FBAD812B478F3BE060BD64350348A722F22E838B7E573C98D29`。
- 用于《青云宗》固定院落运行背景，建筑仍由游戏独立绘制，不烘焙建筑、不进入存档。旧背景和候选16保留供历史回退，不覆盖文件。
- AI生成资产按服务适用条款用于本项目，不声称独占版权或经过外部法律审核；未引入外部商标或需另外许可的素材。
- 首次以旧背景作编辑目标的改稿仍过度保留插画风，未接入项目；最终仅使用两张建筑图作风格参考重新生成。

## 最终使用提示词（内置工具）

```text
Asset: BUILDING-FREE 2D isometric game environment, landscape 16:9, production terrain background. Input images 1 and 2 are STYLE/MATERIAL references only, not subjects to copy into output. Create a NEW scene whose stone, garden and terrain look rendered by the same miniature architectural renderer as those two building sprites. Crisp physically based semi-realistic 3D miniature, NOT a painted illustration. Precisely beveled limestone blocks, detailed photogrammetry-like slate rocks, tiny natural moss, realistic finely resolved pine needles and grass blades. The foreground must have the same finely modeled clarity and material finish as the reference temple base, not blurry painterly scenery. Normal architectural proportions, weak outlines, soft natural ambient occlusion, warm upper-left lighting with cool soft cast shadows. 3344x1882 wide high detail landscape composition.
Scene: a Chinese cultivation sect garden atop a broad mountain island amid clouds. Top-down isometric camera around 35 degrees elevation, see top and front-left faces, matching supplied sprites. ONE broad connected buildable garden terrace with a slightly raised back-center temple courtyard, not a repeated staircase of enormous identical squares. Pale warm limestone paths connect eight reserved clear building plots, rich but subdued dark green grass and carefully arranged low planting fills the gaps. A modest pool with stone bank at middle-right. Restrained pines and scholar rocks along garden boundaries. Mountain rock edge at front and sides, cloud sea below, very distant softened blue-gray karst peaks behind. Terrain is realistic modelled limestone and irregular craggy rock, NOT a rectangular board hovering in painted clouds. Main garden objects are understated so the separately rendered buildings will dominate.
Composition must use the following plan, in proportional coordinates of a virtual1672x941canvas; scale up appropriately. Reserve clear flat plots, no plants/cliffs/stairs inside footprints:
back main hall x570..920 y190..285 foot(740,255), clear approach ahead left to(675,300), one low broad stair to lower garden at(800,340). Main hall will extend upwards, so no tall tree behind its central silhouette.
left library x150..330 y330..415 foot(245,390).
left-middle workshop lumber x340..490 y425..500 foot(415,475).
front-left forge x510..690 y545..630 foot(600,610).
right-middle circular training site x1020..1220 y415..500 foot(1120,480).
lower-center-left farm x680..860 y645..735 foot(770,710), soil rather than paving, NO drawn crops.
lower-center-right residence x915..1095 y645..740 foot(1005,720), limestone paving with garden outside.
far-right mine workshop x1325..1495 y615..710 foot(1410,680).
These are invisible plot reservations; do not outline boxes or draw markers. Building plots should look like natural parts of a landscaped sect grounds rather than separate display pedestals. Only main hall has a low raised tier, all other plots lie on ONE continuous gently irregular terrace, connected by consistent modest-width paths. No exaggerated stair flights in middle, no regular repeated plazas. Leave plants outside plots. Add actual soil/stone/grass transitions, small path junctions, subtle paving wear, natural organic garden silhouettes, pale low stone border where needed, but no superfluous decorative props.
ABSOLUTELY NO buildings, temples, houses, towers, pavilions, roofs, characters, text, labels, UI, watermarks, circles showing reserved plots, fences across plots, architectural facade in background. Do not bake the reference buildings into the scene. Environment only, ready for dynamic building sprites placed on top. Do not make a mockup; deliver the full usable terrain image.
```
