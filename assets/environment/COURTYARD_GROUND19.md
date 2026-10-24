# V0.8 局部材质地面试稿（候选19）

- 日期：2026-10-23；状态：局部候选，未获负责人视觉验收。
- 工具：OpenAI内置ImageGen，precise-object-edit；未用CLI/API脚本或第三方下载素材。
- 编辑目标：既有sect_plane_underlay18.png；材质/光照参考：项目既有assets/buildings/main-hall-sample.png。不包含人物照片。
- 输出：sect_courtyard_ground19.png，1672×941，不透明PNG；SHA256 D61D0CA23C759F97B650B69A96890F37BE9436E21A7095AA31EE6999801C12B8。
- 原始输出：Codex生成目录exec-314ef6ac-73e8-4b1a-8e9a-8ec9adf24793.png，已复制进本项目，旧素材保留。
- 使用范围：仅主殿/弟子居两处既有羽化窗口；其余继续候选17。独立建筑未烘焙入背景，不改点击、ID、数据坐标或version3。
- 许可边界：按AI服务适用条款用于本项目，不声称独占版权、精确3D或已完成外部法律审核；来源参考沿用既有素材登记。没有引入额外第三方资产。
- 限制：石材纹理来自生成图，线向仍需负责人目视确认；并非可编辑3D地形，也不是七院落全部完成。

## 既有候选18清除图补登记

- sect_plane_underlay18.png，1672×941，SHA256 F263122DB250AEFBA18996A3DD7F46865B1BAC56CC303F65F070295B6B19EEFE。
- 来源：之前内置ImageGen编辑sect_garden_scene17.png，清除主殿/弟子居旧烘焙台阶平台并补草地；原缓存exec-c72410f4-d671-4263-bbed-d73fbf21f5c5.png。现保留作过程资产。
- 前轮完整生成提示词未单独落盘，此处是用途摘要而非声称恢复原始逐字提示；本轮最终提示词完整记录如下。

## 候选19完整提示词

```text
Use case: precise-object-edit. Asset type: in-game 2D BACKGROUND ONLY for a Chinese cultivation management game. Image 1 (sect_plane_underlay18.png) is the EDIT TARGET, full 1672x941 landscape. Image 2 (main-hall-sample.png) is MATERIAL, LIGHTING AND CAMERA REFERENCE ONLY: never copy any building, roof, column, stairs, plinth or railing from it into the output. Preserve Image 1 exact overall composition, mountain island silhouette, distant mist/mountains, pond, all other six building sites, garden paths and vegetation outside two local sites. No UI or text or buildings anywhere.
Change the empty grassy upper central main hall site and the lower right-center residence site into carefully integrated ground-level warm pale limestone courtyards. This must look like actual terrain belonging to the garden, NOT an inserted geometric plate, grid decal, raised slab or beige rectangle. Use finely varied warm ivory-grey weathered limestone, subtle shallow seams and irregular peripheral moss/grass. Keep centre low contrast, edges broken into grass naturally. Small stones, dirt and moss soften the boundary. No thick straight border, no raised foundation, no duplicated steps. Soft light from upper left same as architectural reference.
TOP SITE: leave the entire future hall footprint x600..915,y70..255 unobstructed and building-free. Match ground direction to the reference main hall: one set of parallel edges slopes down right about +0.40, the other down left about +0.60 (screen x right and y down). A modest connected open ground surface surrounds the future building foundation. Its broad front apron lies around x565..850,y205..290, stone joins subtle and small; make the perimeter meet existing garden ground, not a rigid diamond. Connect this apron down-left from around (680,245) to the existing stone walking route around (620,300) using a short broad stone transition that gently merges at the junction. Do not invent giant ceremonial stairs or make the main hall site a floating platform. Keep plants clear of the hall area.
LOWER RESIDENCE SITE around x910..1175,y540..700: provide a smaller matching worn limestone ground courtyard, clear central footprint x925..1140,y545..660, with a natural moss/dirt edge and short entrance transition toward the existing path at (1010,690). Do not add walls, buildings or props in that footprint.
Both sites must share ground scale, material, coherent orthographic three-quarter camera, and illumination. Keep existing mountain cliffs and distant scenery untouched. Actual gameplay background, not mockup, no rectangular frame, no lettering, no signs, no watermark.
```
